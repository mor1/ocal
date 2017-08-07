(*
 * Copyright (c) 2016-2017 Richard Mortier <mort@cantab.net>
 *
 * Licensed under the ISC Licence; see LICENSE.md in the root of this
 * distribution or the full text at https://opensource.org/licenses/isc-license
 *
 *)

open CalendarLib
open Astring
open Notty
open Notty.Infix

module List = struct
  include List

  let chunk n list =
    list
    |> fold_left (fun (i,acc) e ->
        match (i, n) with
        | (i, n) when i = 0 || n = 1 -> 1, [e] :: acc
        | (i, n) when i < n ->
          let n' = (i+1) mod n in
          let acc' = ((e :: hd acc) :: (tl acc)) in
          n', acc'
        | (_i, _n) (* i >= n *) -> failwith "never reached"
      ) (0, [])
    |> snd
    |> List.(rev_map rev)


  let split n list =
    let rec aux i acc = function
      | [] -> List.rev acc, []
      | h :: t as l ->
        if i = 0 then List.rev acc, l else aux (i-1) (h :: acc) t
    in
    aux n [] list

end

module F = struct
  let s = I.string A.empty
  let b = I.string A.(st bold)
  let iu = I.string A.(st italic ++ st underline)
  let u = I.string A.(st underline)
  let r = I.string A.(st reverse)

  let lpad ?(f=s) ~w x = x |> f |> I.hsnap ~align:`Right w
  let rpad ?(f=s) ~w x = x |> f |> I.hsnap ~align:`Left w
  let centre ?(f=s) ~w x = x |> f |> I.hsnap ~align:`Middle w

  let endl = Notty_unix.output_image_endline
end

let months range =
  let parse ?(rh=false) input =
    let input = String.Ascii.capitalize input in
    Printer.Date.(
      (* monthyear *)
      try from_fstring "%d%b%Y" ("01"^input)
      with Invalid_argument _ ->
        ( (* year *)
          try from_fstring "%d%b%Y" ("01"^(if rh then "Dec" else "Jan")^input)
          with Invalid_argument _ ->
            ( (* month *)
              let thisyear = string_of_int Date.(year (today ())) in
              from_fstring "%d%b%Y" ("01"^input^thisyear)
            )
        )
    )
  in

  let expand st nd =
    let st = parse st in
    let nd = parse ~rh:true nd in

    let rec aux d nd acc =
      match Date.compare d nd with
      | n  when n > 0 (* >  *) -> List.rev acc
      | _n            (* <= *) ->
        let d' = (Date.next d `Month) in
        aux d' nd (d::acc)
    in
    aux st nd []
  in

  match String.cuts ~sep:"-" range with
  | [st; nd] -> expand st nd
  | [st]     -> expand st st
  | _        -> invalid_arg ("invalid date range: " ^ range)

let cal plain weeks today ncols _sep firstday range =
  range
  |> months
  |> List.map (fun monthyear ->
      (* generate list of lines per month *)
      let month, year = Date.(month monthyear, year monthyear) in

      (* header: "Month Year", centred, bold followed by "Mo Tu ... Su",
         underlined (varying first day based on `firstday` *)

      let colheads =
        let wk =
          if not weeks then
            I.void 0 0
          else (
            let iu = if not plain then F.iu else F.s in
            (iu "wk")
          )
        in
        wk
        <|>
        let f = if not plain then F.u else F.s in
        I.hcat (Days.of_week firstday
                |> List.map (fun d -> f (" " ^ Day.to_string d))
               )
      in

      let w = I.width colheads in

      let header =
        let title =
          Printf.sprintf "%s %d" (Printer.name_of_month month) year
        in

        let f = if not plain then F.b else F.s in
        F.centre ~f ~w title
        <->
        colheads
      in

      (* days of the week: first row lpadded, last row rpadded *)

      let days =
        let length = Date.days_in_month monthyear in
        Days.of_month length (* generate list of days of month *)
        |> List.map (fun d ->
            let f =
              if (not plain
                  && Date.year today = year
                  && Date.month today = month
                  && Date.day_of_month today = d
                 )
              then F.r else F.s
            in
            I.hsnap ~align:`Right 3
              (f (Printf.sprintf "%2d" d))
          )
        |> (fun days ->
            let start_full_week =
              Date.nth_weekday_of_month year month firstday 1
              |> Date.day_of_month
            in
            let hd, tl = List.split (start_full_week - 1) days in
            I.hsnap ~align:`Right w
              (I.hcat hd)
            <->
            I.hsnap ~align:`Right w
              (I.vcat (List.map I.hcat (List.chunk 7 tl)))
          )
      in

      (
        header
        <->
        days
      )
      <|>
      I.void 1 0
    )
  |> List.chunk ncols
  |> List.map I.hcat
  |> I.vcat
  |> F.endl
