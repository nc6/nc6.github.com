---
title: Scala, OCaml and Haskell, oh my!
date: 2013-10-03 14:00
author: Nick
comments: true
categories: [scala, haskell, ocaml] 
---

In my previous job, I made heavy use of Scala. I came across it sometime around version 2.7.7, and it was the first language I really fell in love with. My employer at the time made heavy use of Java and the JVM; by writing in Scala, I could link trivially with existing code and allow others to make use of my code without having to learn a new language, whilst getting all the benefits of writing in a modern, statically typed functional language.

Unfortunately my new employer has, for a couple of good reasons and a slew of bad ones, a strong bias against anything that runs on the JVM. I've used Scala for a couple of side projects, but the likelihood of anything JVM-based being allowed for my main work is minimal. Code here mostly seems to be written in Perl or Python or C, none of which was appealing. Perl and C I've always thought of as languages that I 'should learn', but having played with them I'm fairly convinced that the only reason for learning them is to see brilliant examples of how not to do things. Anyway, I had a couple of projects to do, so it seemed like a good opportunity to learn and compare the other two big static functional languages out there, Haskell and OCaml.

<!-- more -->

# OCaml

I started with OCaml first. The local functional programming group ([Cambridge NonDysFunctional Programmers](http://www.meetup.com/Cambridge-NonDysFunctional-Programmers/)) was holding an OCaml session hosted by [OCaml labs](http://www.cl.cam.ac.uk/projects/ocamllabs/), and Anil Madhavapeddy (one of the authors of [Real World OCaml](https://realworldocaml.org)) was giving an introduction based on an alpha copy of the book. I had a chat with Anil and various of the other developers there, and they introduced me to the Jane Street Core library (which replaces the somewhat anaemic standard core library) and the OPAM package manager and I set off to write a fairly simple program for deploying specific LXC containers onto our farm machines.

And... it was okay. It's a language that there's much to like about: it's pretty fast, has an awesome module system, a terse syntax. And yet... it just doesn't inspire the same sort of joy that I originally found programming in Scala. To a large extent, I think this may be a matter of aestetics. When I came across Scala, it appealed to me because of the simplicity of the core spec and the amount of power that comes from it. A lot of effort seemed to have been put into coming up with a simple core of sufficient generality to allow the more powerful structure on top to be expressed in terms of it.

With OCaml, I think I felt the lack of this structure. In ultimately trivial ways, but ways which strongly affect my sense of the language's aesthetic. There's two almost disjoint type systems - one for values, the other for modules. One can define a functor as `module A = functor(x : B) ->` or as `module A(x : B) =`. Nobody seems to use the former syntax, and as far as I can see it offers no benefit over the latter. There's a keyword `rec` that needs to be there when defining recursive functions. There's a whole object system that people seem to advise you not to use, and which most of the libraries seem to avoid.

It just feels like a bit of a mess. I get no sense of a cohesive whole from it, rather a set of semi-interacting features stacked in a haphazard pile. I still like it - I'd choose it above most other languages out there - but I think I would find it hard to love.

# Haskell

My second project involved building a package management system (or at least finding one to use). I'm a big fan of Archlinux: like scala, it has a simple core that allows you to develop a lot of power. The package format in particular is very nice - writing a package is as simple as defining a single file and running one command, which puts it well above any others I've come across (although [Nix](http://nixos.org/nix/) looks interesting.) This was particularly useful for our case, where we wanted to be able to easily construct packages for pieces of software used in genetics research. Unfortunately, the standard tools for Arch use binary builds, and we were keen to be able to archive sources for the various bits of software in use. Looking around for tools to solve this, I came across [Aura](https://github.com/fosskers/aura), an AUR helper which looked like it could easily be retrofitted to support building packages from scratch from the ABS. More to the point, it was written in Haskell.

I've played a little bit with Haskell before, writing a couple of trivial programs, but never enough to get past the stage where the types stopped being a pain and started helping you: I would get to the end of coding and then spend an hour trying to arrange `forM`, `mapM`, `liftM`, `bind` and their ilk in order to get the thing to compile. Working on Aura was the first big project I carried out using Haskell, the first time I used Cabal or had to work out command line argument parsing.

Overall, it went better than my experience with OCaml. The language feels much more clearly defined; outside perhaps a few areas like FFI, I'm confident that I understand the keywords and syntax. The standard library also feels much more consistent; one of the problems with using the Jane Street Core library was that I'd have to go converting between types if I used a function from outside of there, whereas the Haskell core libraries are truly core and shared appropriately. They were also more extensive, covering just about everything I needed to do in terms of system calls. It was still a little bit of a pain working with monad stacks (things such as `[Io String]` were particularly annoying to deal with), but it also had advantages: in OCaml, I naturally wanted to eschew mutable global state, but wasn't certain what to do with runtime configuration. Being forced into a purely function world led me to the reader monad and ultimately made the code a lot tidier, a lesson I can take back and use even in Scala, where such purity isn't enforced.


Ultimately, I ended up writing a companion utility to the original OCaml utility in Haskell, and then rewrote the original in Haskell as well in order to share functionality. Of course, it's possible that had I done things the other way around, I'd have been rewriting them both in OCaml instead!

# Comparison

So, how do they compare? This isn't meant to be an objective comparison - as noted earlier, a lot has to do with my sense of aestetics - but here are some thoughts about things I like or dislike in the different languages:

## Scala
Like:

* Wonderfully simple core that seems to give rise to a great deal of power.
* It was my first programming language love, and will always hold a special place in my heart.
* Implicits; again, a relatively simple mechanism that subsumes the power of Haskell's typeclasses in a more generally applicable way.
* Easy integration with Java and everything on the JVM; this makes it so much easier to get running with in a JVM-based organisation.
* New macro system seems really cool.

Dislike:

* The limits of Scala's type inference can be quite painful, and lead to some rather horrible signatures.
* Integrating with Java means it has `null` and other similar hacks.
* The compiler is slow.
* There's at least a certain amount of runtime and memory overhead to running on the JVM: these are the mostly good reasons people here dislike it.
* The worry that the desire to bring Scala to the mainstream may result in it losing many of the qualities that attracted me to it in the first place.

## OCaml
Like: 

* The module system.
* The ability to be unpure when necessary; for things like graph data structures, this is a big win.
 
Dislike:

* Feels like it's too many things bolted together; I get no sense of consistency.
* The syntax feels a little clunky in places compared to Haskell.
* Lack of support for parallelism. This didn't really come up too much in these projects, but I've made heavy use of Scala's parallel features in the past, and the lack of any real support is a disappointment.

## Haskell
Like:

* The syntax feels very clean compared to both Scala and OCaml.
* Powerful standard library.

Dislike:

* The module system is poor enough to not be existent, which makes things such as records horrible.
* Speaking of which, records.
* Typeclasses. The idea is lovely, but I'm not keen on the hidden, global implementation. Somebody somewhere has shown that using the `ImplicitParams` extension you can actually implement much of Haskell's typeclass system at the value level, which seems much tidier to me, and lets you control scope and bring in alternative instances.

# Conclusion

So, anyway, a brief and biased view of the three main languages I've been using this year. I have also written a couple of things in C, but if I were to compare that then the 'dislike' list would overflow the page, so we'd better leave it off for now. I still love Scala, but I suspect I will be writing more Haskell in the immediate future, possibly coming back to OCaml if I have a particular problem to which I think it'll be amenable.
