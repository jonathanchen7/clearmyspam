# Migrating Clear My Spam to Next.js ➡️

##### February 17, 2024

###### After falling down a dev rabbit hole, I found myself migrating Clear my Spam to Next.js + Vercel over a long weekend. Tedious, but worth it.

---

It's only been a few days since I wrote a [blog post](/blogs/hello-world) about
Clear My Spam's tech stack, and it's already outdated. Oops. I ran into a few
gotchas while migrating my project from CRA (Create React App) to Next.js that I
imagine some other people may also run into, so I wanted to document my process.

> Edit - February 17, 2025:
>
> Exactly a year later, this post is also outdated 🤦‍♂️. I've since migrated Clear My Spam to a Ruby on Rails app! You
> can
> read about it [here](/blogs/rails-migration).

## Why Now?

Have you ever seen this [clip](https://www.youtube.com/watch?v=AbSehcT19u0) from
Malcom in the Middle where Hal discovers a light bulb in his house is burned
out? As he grabs a box of lightbulbs from a shelf in his garage, he realizes
that the shelf is unsteady and also needs to be fixed. This sends him down a
rabbit hole of fixing random items around his house. My "lightbulb" was
[MDX](https://mdxjs.com/) - a neat Markdown superset that allows you to render
Markdown as JSX to create blog posts like this with minimal boilerplate code.

![Screenshot of blog post in Markdown](mdx-screenshot.png "MDXception")

After writing my first blog post in pure JSX, I knew there had to be a better
way of doing this without using a CMS. I found MDX after poking around for a
bit, which seemed to be exactly what I was looking for. The problem? Installing
MDX was an absolute **pain in the ass**. Since I used
[Create React App](https://create-react-app.dev/) to build my React app, there
were dependency conflicts and config issues that I couldn't figure out for the
life of me. Apparently the `47 vulnerabilities (38 moderate, 11 high)` warning I
saw every time I installed a new package isn't the status quo for React? News to
me.

An hour later and I found myself searching `Next.js 14 full tutorial for
beginners` on Youtube. I knew it would be a decent lift to migrate my entire app
to Next.js, but Clear My Spam is ultimately an educational project for me. What
better time to learn Next.js than on my own accord?

## The Process

After spending an hour or two watching YouTube videos on Next.js basics, I got
to work. `create-next-app` conveniently includes templates for TypeScript,
TailwindCSS, and Supabase, so I didn't need to spend too much time with config.
I also created the Next.js project in the same directory as my CRA project so I
could easily reference files and copy them across both projects.

Since I had to touch every single component, I also took the opportunity to
remove the `useContext()` global providers in favor of
[Zustand](https://zustand-demo.pmnd.rs/). I would highly recommend Zustand if
you're using the default React context hooks or Redux to manage global state -
it has minimal boilerplate and state can be accessed _anywhere_ on the client
side, even in service methods. This single change cleaned up many unecessary
function arguments and drasically improved the readability of my frontend logic.

I would recommend migrating a primarily static portion of your app/website first
if possible, which should give you a nice and easy intro into server components
and the app router. I chose to start with Clear My Spam's [marketing site](/).
My general process for each component was straightforward and worked well
enough:

1. Comment out all inner components except for outer container components (e.g.
   headers, footers, navbars).
2. Fiddle around until it compiles without any console errors.
3. Test and verify all functionality.
4. Uncomment a nested component and repeat step 2.

The work was tedious but straightforward, and following the process above
ensured that I never had to to chase a bug down too many layers of components.
Once I completed the marketing site migration and moved onto the app, I was also
able to copy/paste functions over and add `"use client"` at the top of each
component (after refactoring the global state portions to use Zustand).

## Death to Supabase Functions

Since my project was now on Next.js, I decided to move from Netlify to Vercel
for hosting. Turns out, Vercel is also awesome! Its free tier had feature parity
with Netlify, and using Next.js also meant I got a native backend API. It was a
breeze to setup the Next.js backend with Supabase and I was also able to reuse
TypeScript types/interfaces on the backend, which was an underrated benefit.

I'm still not super familiar with
[Deno](https://supabase.com/blog/edge-runtime-self-hosted-deno-functions) (a
requirement for Supabase Functions) so I was happy to stay in Node.js-world. My
VS Code also doesn't play well with the `deno.enablePaths` setting - I would
randomly get Deno server error pop-ups that I was relieved to do away with.
Backend migration was a breeze, and IMO creating APIs in Next.js is
more intuitive than Supabase Edge Functions.

## Final Thoughts

Although the process was probably more time consuming than educational, I'm glad
I took the time to go through this migration. When it comes to code design and
architecture, simply knowing what tools are available is half of the battle.
I'll definitely be using Node.js + Vercel + Zustand for my future projects!
