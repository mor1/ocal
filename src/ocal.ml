(*
 * Copyright (c) 2016 Richard Mortier <mort@cantab.net>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Cmdliner
open Astring
open CalendarLib

module Day : sig
  val of_string: string -> Date.day
  val to_string: Date.day -> string
  val find: Date.day -> int
  val week: Date.day -> Date.day array
end = struct
  let of_string = function
  | "Mon" -> Date.Mon
  | "Tue" -> Date.Tue
  | "Wed" -> Date.Wed
  | "Thu" -> Date.Thu
  | "Fri" -> Date.Fri
  | "Sat" -> Date.Sat
  | "Sun" -> Date.Sun
  | _ as s -> invalid_arg ("invalid day: " ^ s)

  let to_string d = d |> Printer.short_name_of_day |> String.with_range ~len:2

  let _days = Date.([| Mon; Tue; Wed; Thu; Fri; Sat; Sun;
                       Mon; Tue; Wed; Thu; Fri; Sat; Sun
                    |])
  let find x =
    let rec aux a x n = if a.(n) = x then n else aux a x (n+1) in
    aux _days x 0

  let week firstday =
    let i = find firstday in
    Array.sub _days i 7
end

let months range =
  let parse ?(rh=false) s =
    let s = String.Ascii.capitalize s in
    Printer.Date.(
      (* monthyear *)
      try from_fstring "%d%b%Y" ("01"^s)
      with Invalid_argument _ -> begin
          (* year *)
          try from_fstring "%d%b%Y" ("01"^(if rh then "Dec" else "Jan")^s)
          with Invalid_argument _ -> begin
              (* month *)
              let thisyear = string_of_int Date.(year (today ())) in
              from_fstring "%d%b%Y" ("01"^s^thisyear)
            end
        end
    )
  in

  let expand st nd =
      let st = parse st in
      let nd = parse ~rh:true nd in

      let rec aux d nd acc =
        match Date.compare d nd with
        | n when n > 0 (* >  *) -> List.rev acc
        | n            (* <= *) ->
          let d' = (Date.next d `Month) in
          aux d' nd (d::acc)
      in
      aux st nd []
  in

  match String.cuts ~sep:"-" range with
  | [st; nd] -> expand st nd
  | [st]     -> expand st st
  | _        -> invalid_arg ("invalid date range: " ^ range)

module F = struct
  open Printf
  let bold fmt      = sprintf ("\x1b[0;1m"^^fmt^^"\x1b[0m")
  let hilight fmt   = sprintf ("\x1b[0;1;7m"^^fmt^^"\x1b[0m")
  let underline fmt = sprintf ("\x1b[0;4m"^^fmt^^"\x1b[0m")

  let center ~w s =
    let pad = w - String.length s in
    let lpad, rpad =
      let space = fun _ -> ' ' in
      String.(v ~len:(pad/2) space, v ~len:((pad+1)/2) space)
    in
    lpad ^ s ^ rpad
end

let cal plain today ncols sep firstday range =
  months range
  |> List.map (fun date ->
      let open Printf in
      let month, year = Date.(month date, year date) in
      let monthyear = sprintf "%s %d" (Printer.name_of_month month) year
                      |> F.center ~w:20 |> F.bold "%s"
      in
      let week = Day.week firstday
                 |> Array.map Day.to_string
                 |> Array.to_list
                 |> String.concat ~sep:" "
                 |> F.underline "%s"
      in
      let days =
        let rec aux n i acc = if i > n then acc else aux n (i+1) (i::acc) in
        let lastdate = Date.days_in_month date in
        aux lastdate 1 []
        |> List.rev
        |> List.map (fun d -> sprintf "%2d" d)
        |> String.concat ~sep:" "
      in
      let day_offset =
        let lpad = (1 + String.length sep)
                   * (Day.find (Date.day_of_week date))
        in
        String.v ~len:lpad (fun _ -> ' ')
      in
      sprintf "%s%s%s%s" monthyear week day_offset days
    )
  |> List.iter (fun s -> Printf.printf "%s\n%!" s)

(* command line parsing *)

let today =
  let aux =
    let parse date =
      try
        `Ok (Printer.Date.from_string date)
      with
      | Invalid_argument _ ->
        try
          let date = Printer.Date.from_fstring "%y-%m-%d" date in
          (* [Calendar.Date.from_string "%y" xx] defaults to `Year 19xx *)
          `Ok Date.(add date (Period.year 100))
        with
        | Invalid_argument _ ->
          `Error ("invalid date string: " ^ date)
    in
    parse, fun ppf p -> Format.fprintf ppf "%s" (Printer.Date.to_string p)
  in
  let doc = "Set today's date." in
  Arg.(value & opt aux (Date.today ())
       & info ["t"; "today"] ~docv:"yyyy-mm-dd" ~doc)

let ncols =
  let doc = "Format across $(docv) columns." in
  Arg.(value & opt int 3 & info ["c"; "columns"] ~docv:"N" ~doc)

let sep =
  let doc = "Format using $(docv) as month separator." in
  Arg.(value & opt string "  " & info ["s"; "separator"] ~docv:"sep" ~doc)

let firstday =
  let aux =
    let parse day =
      try
        `Ok (day |> String.Ascii.capitalize |> Day.of_string)
      with
      | Invalid_argument s -> `Error s
    in
    parse, fun ppf p -> Format.fprintf ppf "%s" (Printer.short_name_of_day p)
  in
  let doc = "Format with $(docv) as first day-of-week." in
  Arg.(value & opt aux (Date.Mon) & info ["f"; "firstday"] ~docv:"ddd" ~doc)

let plain =
  let doc = "Turn off highlighting." in
  Arg.(value & flag & info ["p"; "plain"] ~doc)

let range =
 let doc = "RANGE." in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"RANGE" ~doc)

let cmd =
  let doc = "pretty print calendar months" in
  let man = [
    `S "DESCRIPTION";
    `P "$(tname) -- pretty prints specified monthly calendars.";

    `S "SEE ALSO";
    `P "cal(1), ncal(1), calendar(3), strftime(3)";

    `S "HISTORY";
    `P
      "Translated from\
      \ https://github.com/mor1/python-scripts/blob/master/cal.py because I got\
      \ tired of the startup time. The Python version was written because I got\
      \ tired of the CLI.";

    `S "AUTHORS";
    `P "Richard Mortier <mort@cantab.net>.";

    `S "BUGS";
    `P "Report bugs at https://github.com/mor1/ocaml-cal/issues.";
  ]
  in
  Term.(const cal $ plain $ today $ ncols $ sep $ firstday $ range),
  Term.info Config.command ~version:Config.version ~doc ~man

(* go! *)

let () =
  match Term.eval cmd with
  | `Error _ -> exit 1
  | _ -> exit 0
