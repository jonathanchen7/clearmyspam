<!--
tags: Development
-->

# Clear My Spam on Rails? 🛤️

##### February 17, 2025

###### After letting Clear My Spam collect dust for nearly a year, I revisited the project. And in typical dev fashion, I decided to completely rewrite the app in Ruby on Rails.

---

I know, I know... my [last blog post](/blogs/nextjs-migration) was about migrating from Create React App to Next.js. But
after months of inactivity and a sudden urge to refactor, I decided to rewrite from scratch in Ruby on
Rails.

## Why?

I currently work as a software engineer at [Modern Treasury](https://www.moderntreasury.com/), a fintech company that
uses Ruby on Rails for its backend. I've been working in Rails for the past 2.5 years and have grown to really
appreciate the
framework and the Ruby language. Since learning Ruby on Rails I haven't gotten to use it in a personal project or even
experiment with a Rails frontend (since my company uses React), so what better way to learn than to
rewrite an existing app?

For some additional context, this rewrite was absolutely not necessary - my Next.js app had few users, no scaling issues,
and worked just fine. It was a little difficult to extend and test (given the lack of OO principles), but my motivation
was purely educational.

If you haven't used Ruby on Rails before, it's a full-stack web app framework that emphasizes **convention over
configuration**. It's a great choice for quickly building web application if you're familiar with
Ruby and/or MVC frameworks and there are a ton of nice-to-have features, like a native database querying API,
powerful routing, and a built-in testing framework. I'm a big fan of Ruby syntax, too.

![Rails string helpers](string-helpers.png "Who doesn't love a good string helper?")

## The Migration

This migration was "straightforward", in the sense that **everything** needed to be rewritten from scratch.
Authorization, payment processing, database models/migrations, webhooks, background jobs, etc. This did, however,
present the perfect opportunity to clean up some old code. I turned TypeScript service classes into Ruby models, added
tests, and took advantage of some great gems (i.e. Ruby packages) to make my life 100x easier.

Specific shoutout to these gems:

- `devise` for user authentication
- `good_job` for background jobs
- `view_component` for reusable object-oriented frontend components
- `redcarpet` for Markdown rendering
- `faker` and `factory_bot_rails` for testing

Thankfully, much of my React frontend was standard HTML + Tailwind classes, so I was could do a good amount of
copy/pasting (and a massive find/replace from `className` to `class`). The biggest challenge in migrating the frontend
was learning [Hotwire](https://hotwired.dev/) - the API isn't as intuitive as React's, but it's
very powerful once you get the hang of it.

React's greatest strength is its high level of abstraction. This is great for
rapid iteration/development, but often leaves developers with a lackluster understanding of what's actually happening
under the hood. Learning Hotwire greatly improved my understanding of the DOM and boosted my confidence in manipulating
it.

Being away from Clear My Spam for a while also provided a fresh perspective on the fronted + UX, leading to quite a few
design tweaks. After many revisions and feedback from friends and family, I'm really happy with the final result. The
app is more intuitive, user-friendly, and focused on its core functionality.

![Clear My Spam UI comparison](mockup-comparisons.png "Look how far we've come...")

## Deploying

I decided to deploy the Rails app on [Render](https://render.com), as they seemed like the most cost effective option
for a small personal project (as compared to Heroku). The deployment process was pretty straightforward - I followed
Render's [Rails deployment guide](https://render.com/docs/deploy-rails) and the app was live within a few hours,
including a database, background workers, and a custom domain. I would highly recommend Render for small projects like
this one.

## Final Thoughts

I am **extremely** happy with the result of this refactor. The codebase is cleaner, more organized, and only 60%
the size of the original TypeScript codebase (while being more feature-rich). I learned how to build and deploy a Rails
app from scratch, and feel confident in my ability to test and extend the app.

To my fellow developers - if you've never written a full stack app from scratch using the same language/framework as your
company, I would highly recommend trying it out. The easiest way may just be to rewrite one of your personal projects! 
Unless you were a founding or early engineer, there are likely tons of setup/configuration bits that you've never had
to deal with (especially for Rails). Going through the process from scratch forces you to learn about many framework
and language quirks that you might otherwise not know about or interact with. 

![React app lines of code](react-loc.png "Ruby on Rails lines of code")
![Ruby on Rails lines of code](rails-loc.png "Ruby on Rails lines of code")





