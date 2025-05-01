import tempo
import tempo/date
import tempo/datetime

pub fn localized_date(date: tempo.DateTime) -> String {
  let day_of_week =
    date
    |> datetime.get_date
    |> date.to_day_of_week
  case day_of_week {
    date.Mon -> "Lundi"
    date.Tue -> "Mardi"
    date.Wed -> "Mercredi"
    date.Thu -> "Jeudi"
    date.Fri -> "Vendredi"
    date.Sat -> "Samedi"
    date.Sun -> "Dimanche"
  }
}
