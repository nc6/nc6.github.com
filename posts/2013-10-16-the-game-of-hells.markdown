---
title: The Game of Hells (or Cows and Bulls)
date: 2013-10-16 18:29
author: Nick
comments: true
categories: [haskell, games] 
---

The game of hells
=================

My girlfriend's company ([red gate](http://www.red-gate.com), who sound like a pretty cool place to work) have regular code katas as a training activity. It's a nice way to force yourself to think about interesting problems potentially outside of what you usually do and discuss them with other people, as well as providing a good vehicle for code review where everyone is aware of the problem in hand.

Despite not working there, I occasionally get sent the problems and try to solve them. This week's involved the game of [Cows and Bulls](http://en.wikipedia.org/wiki/Bulls_and_cows). This has many names, but I first came across it under the name of 'Hells' in the _Mask of the Betrayer_ expansion to Neverwinter Nights 2. The game is described as thus:

1. The _setter_ picks a four digit number, none of whose digits are the same. The object of the game is for the guesser to determine what this number is.

2. The _guesser_ proceeds by guessing a four digit number. The setter will then tell them two things: the count of digits which are guessed correctly in the correct place (the _bulls_), and the count of digits which are guessed correctly but in an incorrect position (the _cows_). The guesser continues until they have correctly guessed the number.

The object of the kata was to write a program that takes the role of the guesser, and manages to find the correct answer in the minimum number of guesses. However, for easy testing of this, it seems appropriate to also write something to set problems.

The setter
==========

We start off by defining some common datatypes:

````haskell
-- | Four places
data Guess = Guess [Int] deriving Show

  -- | Response
data Response = TryAgain Int Int -- ^ TryAgain bulls cows
              | Victory 
              deriving (Eq, Show)
````

A guess consists of an array of `Int`s. We could explicitly say that a `Guess` consists of four `Int`s, but leaving it as a list makes things a little easier later, as well as making it easy in theory to generalise the game to other sizes. [^1] A response to that guess is either a victory or a request to 'try again', giving the number of bulls and cows.

We should consider how to score a guess. The number of bulls is the number of places in which the digits match. We can easily express this by zipping the two lists together, filtering according to an equality predicate and counting the result. The number of cows is then simply the intersection of the two lists treated as sets minus the number of bulls:

```haskell
score :: [Int] -> [Int] -> Response
score a b = case (bulls, cows) of
    (4, 0) -> Victory
    _ -> TryAgain bulls cows
  where
    cows = (length $ intersect a b) - bulls
    bulls = length . filter (\(x,y) -> x == y) $ zip a b
```

We can now define something to set problems.

````haskell

-- | Game solution
data Game = Game Guess deriving Show

-- | Set a new game
set :: IO Game
set = newStdGen >>= \rand ->
  return . Game . Guess $ take 4 . nub $ randomRs (0,9) rand

-- | Answer a guess.
answer :: Game -> Guess -> Response
answer (Game (Guess a)) (Guess b) = score a b
````

A solution is effectively same as a guess, and a game consists of a picked guess. To set a game, we generate an list of random numbers between 0 and 9 using `randomRs`. We then remove duplicates from this list and take the first 4. Since Haskell is lazy by default, it will only generate enough elements necessary to provide our four non-duplicates. Answering a guess is simply a case of scoring the guess against the solution.

The guesser
===========

Since the objective of the kata is to write a program that guesses in as few moves as possible, it would be good if our program allowed us to test multiple strategies. To do this, we want to abstract out what a guesser needs to do. A guesser wants to make a number of moves. At each move, it needs to take all of its information from previous moves and use that to output a new `Guess`.

First we define a move, a game history and a result - a move is just a combination of guesses and responses, and a history is a sequence of moves. We want the history so we can display the series of moves made to the user. The result simply gives us the state at the end of the game, where we either win with a move history, or we give up having exceeded some number of moves without guessing correctly.

```haskell
data Move = Move Guess Response deriving Show

type History = [Move]

-- | Result - can either win or give up after a certain number of tries.
data Result = Win History | GiveUp Int deriving Show
```

What about the guesser? My first thought was that this should be a function from `History` to `Guess` - something that takes a series of moves and returns a new guess based on that series of moves. However, a series of moves isn't necessarily the best way of carrying around the information required by a strategy. So instead we would like to parametrise a strategy over an arbitrary state `a` and define a guesser as a function from `a` to `Guess`:

```haskell
-- | Guesser takes a state and emits the next guess.
type Guesser a = a -> Guess
```

What do we require of that state? Well, we need a way to initialise it before the first guess is made. We also need a way to update it in light of a new move. So that leads us to the following definition:

```haskell
class GameState a where 
  szero :: a
  supdate :: Move -> a -> a
```

Finally, we implement a `play` method - this takes a guesser, a game, and a maximum number of tries, and returns a `Result` after repeatedly invoking the guesser on successive states. The definition is pretty simple:

```haskell
play :: GameState a => Guesser a -> Game -> Int -> Result
play guesser game maxTries = go [] szero where
  go history state 
    | length history > maxTries = GiveUp maxTries
    | otherwise = let 
          guess = guesser state 
          response = answer game guess
          nextmove = Move guess response
          newhistory = nextmove : history
        in case response of
          Victory -> Win newhistory
          _ -> go newhistory (supdate nextmove state)
```

We start off by initialising history to `[]` (we keep the history so we can show it at the end) and `state` to `szero`. We then check that we have guesses remaining (or otherwise give up), ask the guesser for the next guess, ask the setter to check that guess, add the move onto the history and then check the response. If it's a victory, we return a result. Otherwise, we update the state and recurse. Not that we need to care given how many moves we're making, but since the recursive call is in tail position the compiler can optimise it away and convert this into a single loop.

The Strategy
============

I spent quite a while trying to think of a sensible strategy for this. I initially wanted to do something probabilistic, but after a page of scribbles decided that the posterior distributions were somewhat more hairy than I wanted to contend with. Then I thought about some heuristic approximation scoring each number. Finally, I gave up. My girlfriend was tackling the problem by starting with every possibility and then on each turn removing those which had been invalidated by the previous move and guessing the remaining one which was in some way 'most informative'. I decided to go even simpler than this. The simple strategy updates state by removing everything which would have scored the guess differently to the answer. It then picks the first one. I was actually slightly surprised by just *how* simple this is to write:

```haskell
newtype State = State { unState :: [[Int]] }

instance GameState State where
  szero = State [[a,b,c,d] | a <- [0 .. 9]
                     , b <- [0 .. 9] \\ [a]
                     , c <- [0 .. 9] \\ [a,b]
                     , d <- [0 .. 9] \\ [a,b,c]]
  supdate (Move (Guess g) r) = State . filter (\g2 -> score g g2 == r) . unState

guess :: Guesser State
guess = Guess . head . unState
```

It almost defies explanation. We initialise the state with every possibility. We update it by filtering those whose score doesn't match the response. Finally, `guess` just picks the head of the list. The only confusing thing is the required use of `newtype` to allow us to define an instance.

The Result
==========

And, amazingly, this works quite well. It's been proven that the problem is solvable for any number in seven moves. This doesn't quite achieve that, but the maximum number of moves I've seen is nine, with an average of 5.57 (against a minimum of 5.21), which seems pretty good for such a simple strategy. I'm still trying to think of a nice way to do it, but I'm surprisingly happy with this for now.

If anyone wants to play around with the code, it's available at [github](https://github.com/nc6/hells). The binary 'hells' allows you to either play against the computer (any arguments other than 'simple') or watch the simple strategy play a game (with 'simple' as the sole argument).


[^1]:An approach combining both the safety of explicit arity and extensibility of using a list would be to use dependent types, and allow `List` to be parametrized over its size. Haskell doesn't yet allow full dependent types, although it looks like a lot can be achieved with the [XDataKinds](http://www.haskell.org/ghc/docs/7.6.1/html/users_guide/promotion.html) extension, which allows values to be automatically lifted into types.