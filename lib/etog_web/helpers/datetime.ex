defmodule EtogWeb.Helpers.Datetime do
  @moduledoc false

  @fallback_locale "en"
  @months_abbr %{
    "en" => {"Jan.", "Feb.", "Mar.", "Apr.", "May", "June", "July", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."},
    "ru" => {"Янв.", "Фев.", "Март", "Апр.", "Май", "Июнь", "Июль", "Авг.", "Сен.", "Окт.", "Ноя.", "Дек."}
  }

  import EtogWeb.Gettext, only: [gettext: 1, ngettext: 3]

  def month_abbr(num, locale) when is_integer(num) do
    (@months_abbr[locale] || @months_abbr[@fallback_locale])
    |> elem(num - 1)
  end

  def month_abbr(date, locale) do
    num = date.month
    month_abbr(num, locale)
  end

  def job_duration(from, to) do
    from_date = Date.from_iso8601!(to || Date.to_string(Date.utc_today()))
    to_date = Date.from_iso8601!(from)
    humanize_duration(Date.diff(from_date, to_date), [{365, gettext("y")}, {30, gettext("m")}], "")
  end

  def short_humanize_duration(duration) do
    humanize_duration(duration, [{365, gettext("y")}, {30, gettext("m")}], "")
  end

  def long_humanize_duration(duration) do
    humanize_duration(
      duration,
      [
        {365, fn val -> ngettext("%{count} year", "%{count} years", val) end},
        {30, fn val -> ngettext("%{count} month", "%{count} months", val) end},
        {1, fn val -> ngettext("%{count} day", "%{count} days", val) end}
      ],
      " "
    )
  end

  def humanize_duration(duration, format, sep) do
    {_, parts} =
      format
      |> Enum.reduce({duration, []}, fn {div, measure}, {days, acc} ->
        val = trunc(days / div)

        part =
          if is_binary(measure) do
            "#{val}#{sep}#{measure}"
          else
            measure.(val)
          end

        acc = if val > 0, do: acc ++ [part], else: acc
        {rem(days, div), acc}
      end)

    Enum.join(parts, ", ")
  end
end
