# Clear My Spam

[Clear My Spam](https://clearmyspam.com) is an open source Ruby on Rails app designed to declutter your Gmail inbox, with an emphasis on
simplicity, usability, and security.

[https://clearmyspam.com](https://clearmypam.com)

## Requirements

- [Ruby on Rails](https://rubyonrails.org/) `>= 7.2.1.1`
- [Overmind](https://github.com/DarthSim/overmind) - Used to run the web and background job servers.

## Software + Tooling

- [Ruby on Rails](https://rubyonrails.org/)
- [Hotwire](https://hotwired.dev/)
- [PostgreSQL](https://www.postgresql.org/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Tailwind UI](https://tailwindui.com/)
- [Render](https://render.com/) (for hosting)

## Running Locally

1. Clone the repository.
2. Install Ruby on Rails (if you haven't.)
3. Run `bundle install` to install Rails dependencies and `npm install` to install [Hotwire](https://hotwired.dev/).
4. Run `rails db:setup` to create a development database and run migrations.
5. Delete `development.yml.enc` and `development.key` from `config/credentials/` and replace them with your own ([Ruby on Rails Guide](https://guides.rubyonrails.org/security.html#custom-credentials)).
    ```yml
    # Gmail, Stripe, and Honeybadger credentials are optional. Without them, you may see some errors when running tests.
    google:
      client_id: <client_id>
      client_secret: <client_secret>
    gmail:
      mailer_password: <gmail_app_password>
    stripe:
      api_key: <stripe_api_key>
      weekly_price_id: <stripe_weekly_price_id>
      monthly_price_id: <stripe_monthly_price_id>
    honeybadger:
      api_key: <honeybadger_api_key>
    ```
6. Use [`overmind`](https://github.com/DarthSim/overmind) to run the app locally + debug.
    ```bash
    # Use this command to start the web server, background job server, and live reloading for ERB + Tailwind changes.
    overmind start
    
    # If you want to connect to the web server or background job server separately for debugging, use these commands.
    overmind connect web
    # good_job is Clear My Spam's background job backend of choice for async email deletion.
    overmind connect good_job
    ```
7. Run tests with `rails test`.

