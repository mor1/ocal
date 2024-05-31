(*
 * SPDX-FileCopyrightText: 2016 - 2024 Richard Mortier <mort@cantab.net>
 *
 * SPDX-License-Identifier: ISC
 *)

open CalendarLib

let of_week firstday =
  let days = Date.([| Mon; Tue; Wed; Thu; Fri; Sat; Sun;
                      Mon; Tue; Wed; Thu; Fri; Sat; Sun
                   |])
  in
  let find x =
    let rec aux a x n = if a.(n) = x then n else aux a x (n+1) in
    aux days x 0
  in

  Array.sub days (find firstday) 7
  |> Array.to_list

let of_month monthyear =
  let length = Date.days_in_month monthyear in
  let rec aux a b =
    if a > b then [] else a :: aux (a+1) b
  in
  aux 1 length
