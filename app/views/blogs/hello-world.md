<!--
tags: Clear My Spam
-->

# Hello, World! 👋

##### February 12, 2024

###### In Clear My Spam's inaugural blog post, I introduce myself, discuss my motivations for building the app, and review the tech stack.

---

Hello there! My name is Jonathan Chen, the sole developer of Clear My Spam. I'm
a life-long Seattelite, University of Washington computer science graduate (**Go
Dawgs!**), and have been a full time software engineer for the past 1.5 years.
I'm been working on Clear My Spam on and off for the past few months as a side
project.

## Why Clear My Spam?

When I started college at the University of Washington in 2018, I wasn't sure if
I would enjoy coding. My primary motivations behind studying computer science
had always been my general love of technology, in addition to the shallow
observation that software engineers made good money. Well, it turns out I enjoy
software development much more than I originally anticipated.

As I mentioned in the [FAQs](/faq), I (very imformally) diagnosed myself with
"digital OCD". My email inbox is consistently empty, I reorganize my Google
Drive every other month, and I'm a Notion power user. My amazing and awesome and
beautiful wife, on the other hand, is not of the same mindset. Her email
accounts were consistently between 1-2k unread messages, and seeing her go
through her emails stressed **me** out. And because I'm always itching to start
a new project, Clear My Spam was born.

## Tech Stack

If you're not into coding, this section will be useless. Skip it!

I'm a big proponent of templates abd premade design systems, which allows me to
build and iterate with flexibility while spending minimal time on config or
design. This is especially important to me when building something with zero
traction or outside interest - I'm very susceptible to over-engineering my own
projects, so this philosophy helps me tame that impulse. That's reflected in my
chosen tech stack.

> _Edit: February 20, 2024_
>
> This section was made semi-irrelevant only two days after writing this post by
> my decision to migrate my Create React App project to Next.js. You can read
> about it [here](/blogs/nextjs-migration)!

#### TypeScript + React

There's not too much behind this decision. I'm super
comfortable with the lanuage/framework and have built multiple
feature-complete web apps with this combo. **I know** they're not the most
efficient or fully-featured (yada yada yada), but they have a massive active
community and get the job done. I do have tentative plans to migrate the
backend to Ruby on Rails, though.

#### TailwindCSS + TailwindUI

I was introduced to these tools at my current job
and they've dramatically sped up my frontend workflow. Give them a shot if you
haven't already!

#### Supabase

This was the first time I've worked with Supabase, and so far
I've been loving it. They offer a ton of nice-to-have developer tools in
addition to their primary database product (e.g. auth, serverless functions,
storage), the JavaScript SDK is easy to use, and their free tier is generous.

#### Netlify

As far as hosting React apps go, Netlify is the clear winner for
me. I can host a React app from a private Git repo with continous deployment
on a custom domain in less than 5 minutes - absolute wizardry. Similar to
Supabase, their free tier is also incredible!

#### Stripe

I don't have particularly high expectations for the earning
potential of Clear My Spam, but I've always wanted to build a self-sustaining
app. In my case, that entails covering ~$45 in monthly subscriptions that keep
this app running (at least at my current scale of < 10 users). And like every
other SaaS solo dev, I chose Stripe as my payment processor of choice.

## Baby Steps

I'm of the "move fast and break things" mindset, if you couldn't tell. I'm also
not a designer and would _barely_ consider myself a frontend engineer. As a
result, my side projects don't exist in Figma, utilize generic design systems +
templates, and require countless iterations to reach an acceptable state. That
was no different for Clear My Spam. I think I'll save myself some unnecessary
refactoring hours on my future projects by making design mocks and thinking
through architecture beforehand. Or not - sometimes my eagerness (or impatience)
wins out.

![Screenshot of Clear My Spam v0](old-mockup.png "Clear My Spam v0, courtesy of TailwindUI.")

Regardless, a few hours here and there over the course of a few months stacks
up! I'm proud of Clear My Spam and think it looks good, works well, and solves a
real problem. The complexity of this app is well beyond any of my previous side
projects and is the first one I actually feel comfortable selling (btw if you're
reading this and know me personally you don't need to pay - text me!).

!["It ain't much, but it's honest work" meme](honest-work-meme.jpeg "It ain't much, but it's honest work")

## What's Next?

The short answer: I don't know! I'm dedicated to maintaining Clear My Spam in
the near term, but the amount of long-term effort I put in will likely depend on
if people like or use it. In the meantime, there's a lot of code to be cleaned
up, features to add, and emails to delete.

Thanks for reading to the end! This is my first ever blog post and I'm not used
to sharing my writing, so be nice.
