defmodule Spherium.PassphraseInvalidationView do
  use Spherium.Web, :view

  def render("show.json", %{passphrase_invalidation: passphrase_invalidation}) do
    %{data: render_one(passphrase_invalidation, Spherium.PassphraseInvalidationView, "passphrase_invalidation.json")}
  end

  def render("passphrase_invalidation.json", %{passphrase_invalidation: passphrase_invalidation}) do
    %{ip_addr: passphrase_invalidation.ip_addr,
      timestamp: passphrase_invalidation.inserted_at}
  end
end
