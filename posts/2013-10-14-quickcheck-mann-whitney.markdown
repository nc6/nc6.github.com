---
title: Using QuickCheck to generate test datasets.
date: 2013-10-14 16:33
author: Nick
comments: true
categories: [haskell, quickcheck, statistics] 
---

Recently, I've been working on implementing annotations for the [Samtools](https://github.com/samtools/samtools) library for dealing with aligned genetic sequence data. An 'annotation' in this terminology is a feature associated with some part of the file, be it a specific site in the genome, a specific phase of the underlying read (when the sequence was read from DNA) or the entire file. In this particular case, I've been looking at annotations associated with the entire file; features calculated by looking at all the sequence data which we then intend to feed into a regression system to tell us how 'good' we think the particular sample is.

One of the tests we'd like to perform is to determine whether there's any bias in the positions along the genome of reads that are mapped as 'variants' - i.e. they do not correspond to the corresponding allele in the reference genome. On a large scale, there should be no correlation between the position of the read in the genome and its propensity to be a variant (this is not true on a small scale - there exist regions where variants are far more likely, but the location of these regions is roughly uniform). This sort of test - trying to determine whether the positions of two sets of data are different - is an obvious candidate for the [Mann-Whitney U Test](http://en.wikipedia.org/wiki/Mann–Whitney_U). The Mann-Whitney U (or Wilcoxon Rank-Sum - the two tests are subtly different but trivially related) is a non-parametric test of the null hypothesis that two groups of observations are drawn from the same distribution. It's non-parametric because it doesn't assume normality of the two underlying distributions (very useful in this case, where that's an explicit non-assumption), and it works only by considering the ranks of items in each group in an ordering of the two groups.

This is particularly useful in this scenario - because we are comparing the positions of reads, we can calculate the Mann-Whitney U in a single pass through the data with no need to perform an ordering.

Samtools is written in C, but a recent venture with the language has convinced me that it's nowhere I want to voluntarily be, so I've been writing code to test whether this is a useful annotation in Haskell. One of the advantages of this is the wonderful [QuickCheck](http://en.wikipedia.org/wiki/QuickCheck) library. For those of you who haven't come across it, the premise is that you define some sort of invariant you wish your code to satisfy and the library generates random data suitable to test that invariant. In this case, we were interested in making sure that the Normal approximation to the U distribution was suitably accurate.

QuickCheck works through the `Arbitrary` typeclass. An instance for `Arbitrary a` gives a mechanism to generate an arbitrary instance of `a`. In this case, we were looking to test that for arbitrary pairs of lists of integers, given they were of suitable size, the normal approximation to the U-distribution is sufficiently close to the exact calculation.

An advantage of QuickCheck which I didn't really take advantage of here is that, once you have an `Arbitrary` instance for `a`, it's trivial to define one for `[a]` or `(a, a)`. In this case, I wanted to enforce additional constraints (and it was my first time using quickcheck), so I wrote one directly:

    newtype TestRange = TestRange { unTestRange :: ([Int], [Int]) } deriving (Eq, Ord, Show)
    instance Arbitrary TestRange where
      arbitrary = do
        n1 <- choose (1,32) :: Gen Int -- size of the list
        n2 <- choose (1,32) :: Gen Int -- size of second list
        randoms <- forM [0 .. (n1 + n2)] (\_ -> choose (1,20) :: Gen Int)
        return $ TestRange $ splitAt n1 $ randoms

With this in hand, it's very easy to write quick tests of invariants:

    prop_normalApproxEqualsExactRegion :: TestRange -> Property
    prop_normalApproxEqualsExactRegion (TestRange (a,b)) = let mag = length a * length b in
    (mag > 64 && mag < 100) ==> abs (mwNormal a b - mwExact a b) < 0.05

This test was confirming that using the product of the sizes of the two groups was a suitable threshold to decide when to approximate. The usual literature suggests that the normal approximation is 'good' for sample sizes bigger than 8, but mostly considers sample sizes which are roughly equal. We expect very unequal sample sizes, and so may frequently have situations where one group is of size 2 and another may be in the thousands, making calculation of the exact U statistic unfeasible. Using a region bound (which seems just as good an indicator of test performance) makes these situations much easier to handle.

After mentioning that I was testing on random data, my collaborator asked me to produce some charts showing the performance of the approximation with the product of the group sizes, as well as exploring the relative performance of using the standard normal approximation, and an approximation which corrects for the presence of tied ranks in the input data. Luckily, it's quite easy to use the arbitrary instances directly to generate data for export or graphing:

    -- | TestResult n1 n2 exact normal
    data TestResult = TestResult Int Int Double Double Double deriving Show

    genResult :: Gen TestResult
    genResult = let 
        filter (TestRange (a,b)) = (length a) * (length b) < 200
      in do
        TestRange (a,b) <- suchThat (arbitrary :: Gen TestRange) filter
        let u@(MWData _ n m _ _ ) = uFromDataList a b
            exact = min (exactP u) 1
            normal = normalP u
            normalUnc = normalUncorrectedP u
        return $ TestResult n m exact normal normalUnc

    -- Generate some data for graphing and write to a file.
    graphData :: Int -> String -> IO ()
    graphData count fileName = withFile fileName WriteMode go where
      go handle = do
        rand <- newStdGen
        let rnds rnd = rnd1 : rnds rnd2 where (rnd1, rnd2) = split rnd
            results = [(unGen genResult r n) | (r,n) <- rnds rand `zip` [0..count]]
        mapM (hPutStrLn handle . show) results
        return ()