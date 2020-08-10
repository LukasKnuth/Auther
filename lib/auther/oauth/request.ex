defmodule Auther.OAuth.Request do
  alias Auther.Users.User
  alias Auther.OAuth.Client

  @type t :: %__MODULE__{
          scopes: MapSet.t(),
          user: User.t(),
          response_type: String.t(),
          client: Client.t(),
          redirect_uri: String.t() | nil,
          state: String.t() | nil
        }

  defstruct [:scopes, :user, :response_type, :client, :redirect_uri, :state]

  def new(scopes, client, user, response_type, redirect_uri, state) do
    %__MODULE__{
      scopes: scopes,
      user: user,
      response_type: response_type,
      client: client,
      redirect_uri: redirect_uri,
      state: state
    }
  end
end
