using Graphs
using GraphMakie, CairoMakie
using Chain
using LayeredLayouts

const ϕ = (1 + √5) / 2

macro map(col, steps...)
  quote
    map($col) do item
      @chain(item, $(steps...))
    end
  end
end

# The duration of a sequence of dots and dashes
height(morse) = @chain morse collect map(_) do c
  Dict('.' => 1, '-' => 2)[c]
end sum

# By treating each . as 0 and each - as 01 in base Fibonacci, e.g.
#
#   --.-. = 01010010 = F_8 + F_6 + F_3
#
# we can label all the sequences of the same duration with consecutive
# integers. This function uses base ϕ as a shortcut.
basefib(morse) = @chain morse collect map(_) do c
  Dict('.' => "0", '-' => "01")[c]
end join "0" * _ reverse enumerate map(_) do (i, c)
  c == '1' ? ϕ^(i - 1) : 0
end sum

morseplot(labelfunc = first, table = morsetable) = begin
  g = @chain table length SimpleDiGraph
  force_order = Pair{Int,Int}[]
  colors = Symbol[]

  for (i, l) in @chain table first.() enumerate
    for (j, r) in @chain table first.() enumerate
      if l * "." == r
        add_edge!(g, i => j)
        push!(colors, :steelblue)
      elseif l * "-" == r
        add_edge!(g, i => j)
        push!(colors, :brown)
      elseif endswith(l, ".") &&
             endswith(r, "-") &&
             l[1:end-1] == r[1:end-1]
        add_edge!(g, i => j)
        push!(colors, :darkkhaki)
      elseif endswith(l, "..") && endswith(r, "-") && l[1:end-2] == r[1:end-1]
        push!(force_order, i => j)
      end
    end
  end

  _, ax = graphplot(
    g,
    # curves = false,
    nlabels = labelfunc.(table),
    # size = (720, 720),
    # # method = :buchheim,
    # fontsize = 20,
    nlabels_textsize = 20,
    # nlabels_offset = Point(-0.1, -0.1),
    # nlabels_color = :blue,
    edge_color = colors,
    node_attr = (; marker = ' '),
    figure = (; resolution = (720, 720)),
    layout = g -> begin
      x, y, _ = solve_positions(
        Zarate(),
        g,
        force_order = force_order,
        force_layer = @chain table first.() height.() enumerate map(t -> Pair(t...), _)
      )
      Point.(y, -x)
    end
    # layout = _ -> Point.(
    #   (@map table first (basefib(_) + 1) / (ϕ^height(_) + 1)),
    #   (@map table first height -_)
    # ),
  )
  hidedecorations!(ax)
  hidespines!(ax)
  # ax.aspect = 0.1
  current_figure()
end

function make()
  morseplot(first, morsetablecore)
  save("ditsdahs.svg", Makie.current_scene(), resolution = (860, 600))
  morseplot(last, morsetablecore)
  save("alphabet.svg", Makie.current_scene(), resolution = (860, 600))
  morseplot(last, morsetable)
  save("extended.svg", Makie.current_scene(), resolution = (860, 600))
  nothing
end

morsetable = [
  "" => " ",
  "." => "E",
  "-" => "T",
  ".." => "I",
  "-." => "N",
  ".-" => "A",
  "--" => "M",
  "..." => "S",
  "-.." => "D",
  ".-." => "R",
  "--." => "G",
  "..-" => "U",
  "-.-" => "K",
  ".--" => "W",
  "---" => "O",
  "...." => "H",
  "-..." => "B",
  ".-.." => "L",
  "--.." => "Z",
  "..-." => "F",
  "-.-." => "C",
  ".--." => "P",
  "---." => "Ó",
  "...-" => "V",
  "-..-" => "X",
  ".-.-" => "Ä", # Also newline
  "--.-" => "Q",
  "..--" => "Ü",
  "-.--" => "Y",
  ".---" => "J",
  "----" => "Ĥ",
  "....." => "5",
  "-...." => "6",
  ".-..." => "&",
  "--..." => "7",
  # "..-.." => "***",
  "-.-.." => "Ć",
  # ".--.." => "***",
  "---.." => "8",
  # "...-." => "***",
  "-..-." => "/",
  ".-.-." => "+",
  # "--.-." => "***",
  # "..--." => "***",
  "-.--." => "(",
  # ".---." => "***",
  "----." => "9",
  "....-" => "4",
  "-...-" => "=",
  # ".-..-" => "***",
  # "--..-" => "***",
  # "..-.-" => "***",
  # "-.-.-" => "***",
  # ".--.-" => "***",
  # "---.-" => "***",
  "...--" => "3",
  # "-..--" => "***",
  # ".-.--" => "***",
  # "--.--" => "***",
  "..---" => "2",
  # "-.---" => "***",
  ".----" => "1",
  "-----" => "0",
]

morsetablecore = @chain morsetable filter(_) do x
  isascii(last(x)) && isletter(last(x)[1]) || last(x) == " "
end

;
