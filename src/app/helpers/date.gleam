import tempo
import tempo/date
import tempo/datetime
import tempo/time

pub fn meal_moments(meal_datetime: tempo.DateTime) -> String {
  let day =
    meal_datetime
    |> localized_date
  let time_left_in_day =
    datetime.time_left_in_day(meal_datetime)
    |> time.get_hour
  case time_left_in_day {
    t if t > 10 -> day <> " midi"
    _ -> day <> " soir"
  }
}

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
