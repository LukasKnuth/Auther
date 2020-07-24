# Auther

An OAuth 2.0 compliant authentication service for CodeIsland.org

## Features

* Secure Login via Username/Password and 2FA
* Group based access to Services and specific Service features (via Scopes)
    * Example: Access to the Blog could be for the Group "Copy Editor" which is only save drafts but not publish articles
* Reset my Password functionality
* (TBD) Login via 3rd Party Providers (Discord, etz)

## Configuration

* Rather than adding web interfaces for adding applications or scopes, these are configured in the application
* They are parses at compile time for quick runtime lookup

# Development

To start your Phoenix server:

  * Setup the project with `mix setup`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
