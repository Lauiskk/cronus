defmodule CronusWeb.DashboardLive do
  use CronusWeb, :live_view

  alias Cronus.Sites

  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Cronus.PubSub, "monitoring")
    end

    sites = Sites.list_sites()
    changeset = Sites.change_site(%Cronus.Sites.Site{}, %{active: true})
    {:ok, assign(socket, sites: sites, results: %{}, changeset: changeset, show_modal: false)}
  end

  def handle_info({:check_result, result}, socket) do
    params = %{
      status: result[:status],
      latency: result[:latency],
      checked_at: result[:checked_at]
    }

    results = Map.put(socket.assigns.results, result[:site_id], params)
    {:noreply, assign(socket, results: results)}
  end

  def handle_event("save", %{"site" => site_params}, socket) do
    case Sites.create_site(site_params) do
      {:ok, _site} ->
        sites = Sites.list_sites()
        changeset = Sites.change_site(%Cronus.Sites.Site{}, %{active: true})

        {:noreply,
         socket
         |> assign(sites: sites, show_modal: false, changeset: changeset)
         |> put_flash(:info, "Site created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(changeset: changeset)
         |> put_flash(:error, "Failed to create site")}
    end
  end

  def handle_event("validate", %{"site" => site_params}, socket) do
    changeset =
      %Cronus.Sites.Site{}
      |> Sites.change_site(site_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("toggle_modal", _, socket) do
    changeset = Sites.change_site(%Cronus.Sites.Site{}, %{active: true})
    {:noreply, assign(socket, show_modal: !socket.assigns.show_modal, changeset: changeset)}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    site = Sites.get_site!(id)
    {:ok, _} = Sites.delete_site(site)

    sites = Sites.list_sites()

    {:noreply,
     socket
     |> assign(sites: sites)
     |> put_flash(:info, "Site deleted successfully")}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 p-6 lg:p-10">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
      <div class="max-w-6xl mx-auto">
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 mb-8">
          <div>
            <h1 class="text-3xl font-bold text-base-content">Site Monitoring</h1>
            <p class="text-base-content/60 mt-1">Monitor your websites in real-time</p>
          </div>
          <button phx-click="toggle_modal" class="btn btn-primary gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"
                clip-rule="evenodd"
              />
            </svg>
            Add Site
          </button>
        </div>

        <div class="card bg-base-100 shadow-xl">
          <div class="card-body p-0">
            <div class="overflow-x-auto">
              <table class="table table-zebra">
                <thead>
                  <tr class="bg-base-200">
                    <th class="text-base-content font-semibold">Site</th>
                    <th class="text-base-content font-semibold">URL</th>
                    <th class="text-base-content font-semibold">Status</th>
                    <th class="text-base-content font-semibold">Latency</th>
                    <th class="text-base-content font-semibold">Last Checked</th>
                    <th class="text-base-content font-semibold"></th>
                  </tr>
                </thead>
                <tbody>
                  <%= if Enum.empty?(@sites) do %>
                    <tr>
                      <td colspan="6" class="text-center py-12">
                        <div class="flex flex-col items-center gap-3 text-base-content/50">
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            class="h-12 w-12"
                            fill="none"
                            viewBox="0 0 24 24"
                            stroke="currentColor"
                          >
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="1.5"
                              d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9m-9 9a9 9 0 019-9"
                            />
                          </svg>
                          <p class="font-medium">No sites being monitored</p>
                          <p class="text-sm">Add your first site to start monitoring</p>
                        </div>
                      </td>
                    </tr>
                  <% else %>
                    <%= for site <- @sites do %>
                      <% result =
                        @results[site.id] ||
                          %{
                            status: site.last_status,
                            latency: site.last_latency,
                            checked_at: site.last_checked_at
                          } %>
                      <tr class="hover">
                        <td class="font-medium">{site.name}</td>
                        <td>
                          <a
                            href={site.url}
                            target="_blank"
                            class="link link-hover text-primary"
                          >
                            {site.url}
                          </a>
                        </td>
                        <td>
                          <div class={[
                            "badge gap-1",
                            status_badge_class(result.status)
                          ]}>
                            <span class={["w-2 h-2 rounded-full", status_dot_class(result.status)]} />
                            {status_text(result.status)}
                          </div>
                        </td>
                        <td>
                          <%= if result.latency do %>
                            <span class={latency_color(result.latency)}>
                              {result.latency}ms
                            </span>
                          <% else %>
                            <span class="text-base-content/40">-</span>
                          <% end %>
                        </td>
                        <td>
                          <%= if result.checked_at do %>
                            <span class="text-base-content/70">
                              {Calendar.strftime(result.checked_at, "%H:%M:%S")}
                            </span>
                          <% else %>
                            <span class="text-base-content/40">-</span>
                          <% end %>
                        </td>
                        <td>
                          <button
                            phx-click="delete"
                            phx-value-id={site.id}
                            data-confirm="Are you sure you want to delete this site?"
                            class="btn btn-ghost btn-sm text-error hover:bg-error/10"
                          >
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              class="h-5 w-5"
                              viewBox="0 0 20 20"
                              fill="currentColor"
                            >
                              <path
                                fill-rule="evenodd"
                                d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z"
                                clip-rule="evenodd"
                              />
                            </svg>
                          </button>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>

      <%= if @show_modal do %>
        <div class="modal modal-open">
          <div class="modal-backdrop bg-black/50" phx-click="toggle_modal" />
          <div class="modal-box max-w-md">
            <button
              phx-click="toggle_modal"
              class="btn btn-sm btn-circle btn-ghost absolute right-4 top-4"
            >
              ✕
            </button>

            <h3 class="text-xl font-bold mb-2">Add New Site</h3>
            <p class="text-base-content/60 text-sm mb-6">
              Enter the details of the website you want to monitor.
            </p>

            <.form :let={f} for={@changeset} phx-change="validate" phx-submit="save" class="space-y-5">
              <div class="form-control">
                <label class="label">
                  <span class="label-text font-medium">Site Name</span>
                </label>
                <input
                  type="text"
                  name={f[:name].name}
                  value={f[:name].value}
                  placeholder="My Website"
                  class={["input input-bordered w-full", f[:name].errors != [] && "input-error"]}
                />
                <.field_error field={f[:name]} />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text font-medium">URL</span>
                </label>
                <input
                  type="url"
                  name={f[:url].name}
                  value={f[:url].value}
                  placeholder="https://example.com"
                  class={["input input-bordered w-full", f[:url].errors != [] && "input-error"]}
                />
                <label class="label">
                  <span class="label-text-alt text-base-content/50">
                    Full URL including https://
                  </span>
                </label>
                <.field_error field={f[:url]} />
              </div>

              <div class="form-control">
                <label class="label">
                  <span class="label-text font-medium">Check Interval</span>
                </label>
                <div class="join w-full">
                  <input
                    type="number"
                    name={f[:interval].name}
                    value={f[:interval].value || 30000}
                    min="5000"
                    step="1000"
                    class={[
                      "input input-bordered join-item w-full",
                      f[:interval].errors != [] && "input-error"
                    ]}
                  />
                  <span class="btn btn-disabled join-item">ms</span>
                </div>
                <label class="label">
                  <span class="label-text-alt text-base-content/50">
                    Minimum 5000ms (5 seconds)
                  </span>
                </label>
                <.field_error field={f[:interval]} />
              </div>

              <div class="form-control">
                <label class="label cursor-pointer justify-start gap-3">
                  <input type="hidden" name={f[:active].name} value="false" />
                  <input
                    type="checkbox"
                    name={f[:active].name}
                    value="true"
                    checked={f[:active].value in [true, "true", nil]}
                    class="toggle toggle-primary"
                  />
                  <div>
                    <span class="label-text font-medium">Start monitoring immediately</span>
                    <p class="text-xs text-base-content/50 mt-0.5">
                      Enable to begin checks right after saving
                    </p>
                  </div>
                </label>
              </div>

              <div class="modal-action mt-8">
                <button type="button" phx-click="toggle_modal" class="btn btn-ghost">
                  Cancel
                </button>
                <button type="submit" class="btn btn-primary">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-5 w-5 mr-1"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  Save Site
                </button>
              </div>
            </.form>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp field_error(assigns) do
    ~H"""
    <%= for {msg, _opts} <- @field.errors do %>
      <label class="label">
        <span class="label-text-alt text-error">{msg}</span>
      </label>
    <% end %>
    """
  end

  defp status_badge_class(200), do: "badge-success"
  defp status_badge_class(nil), do: "badge-ghost"
  defp status_badge_class(_), do: "badge-error"

  defp status_dot_class(200), do: "bg-success"
  defp status_dot_class(nil), do: "bg-base-content/30"
  defp status_dot_class(_), do: "bg-error"

  defp status_text(200), do: "Online"
  defp status_text(nil), do: "Pending"
  defp status_text(status), do: "Error #{status}"

  defp latency_color(latency) when latency < 200, do: "text-success font-medium"
  defp latency_color(latency) when latency < 500, do: "text-warning font-medium"
  defp latency_color(_), do: "text-error font-medium"
end
