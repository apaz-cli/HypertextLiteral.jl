#!/usr/bin/env julia
using Faker, HypertextLiteral, Hyperscript, BenchmarkTools

# This is going to simulate a hierarchical report that lists a set of
# companies, and for each company, a list of employees.

Faker.seed(4321)

make_employee() = (
  first_name=Faker.first_name(),
  last_name=Faker.last_name(),
  title=Faker.job(),
  main_number=Faker.phone_number(),
  email=Faker.email(),
  cell_phone=Faker.cell_phone(),
  color= Faker.hex_color(),
  comments= Faker.paragraphs() 
)

make_customer() = (
   company=Faker.company(),
   url=Faker.url(),
   phrase=Faker.catch_phrase(),
   active=Faker.date_time_this_decade(before_now=true, after_now=false),
   notes= Faker.sentence(number_words=rand(2:9), variable_nb_words=true),
   employees=[make_employee() for x in 1:rand(3:18)])

database = [make_customer() for x in 1:13]

htl_database(d) = @htl("""
  <html>
    <head><title>Customers & Employees</title></head>
    <body>
    $([htl_customer(c) for c in d]...)
    </body>
  </html>
""")

htl_customer(c) = @htl("""
    <dl>
      <dt>Company<dd>$(c.company)
      <dt>Phrase<dd>$(c.phrase)
      <dt>Active Since<dd>$(c.active)   
      <dt>Employees<dd>
        <table>
          <tr><th>Last Name<th>First Name<th>Title
              <th>E-Mail<th>Office Phone<th>Cell Phone
              <th>Comments</tr>
          $([htl_employee(e) for e in c.employees]...)
        </table>
    </dl>
""")

htl_employee(e) = @htl("""
      <tr><td>$(e.last_name)<td>$(e.first_name)<td>$(e.title)
          <td><a href="mailto:$(e.email)">$(e.email)</a>
          <td>$(e.main_number)<td>$(e.cell_phone)
          <td>$([htl"<span>$c</span>" for c in e.comments]...)
""")

htl_test() = begin
   io = IOBuffer()
   ob = htl_database(database)
   show(io, MIME("text/html"), ob)
   return io
end

ee(x) = replace(replace(x, "&" => "&amp;"), "<" => "&lt;")
ea(x) = replace(replace(x, "&" => "&amp;"), "\"" => "&quot;")

reg_database(d) = """
  <html>
    <head><title>Customers & Employees</title></head>
    <body>
    $(join([reg_customer(c) for c in d]))
    </body>
  </html>
"""

reg_customer(c) = """
    <dl>
      <dt>Company<dd>$(ee(c.company))
      <dt>Phrase<dd>$(ee(c.phrase))
      <dt>Active Since<dd>$(ee(c.active))
      <dt>Employees<dd>
        <table>
          <tr><th>Last Name<th>First Name<th>Title
              <th>E-Mail<th>Office Phone<th>Cell Phone
              <th>Comments</tr>
          $(join([reg_employee(e) for e in c.employees]))
        </table>
    </dl>
"""

reg_employee(e) = """
      <tr><td>$(ee(e.last_name))<td>$(ee(e.first_name))<td>$(e.title)
          <td><a href="mailto:$(ea(e.email))">$(ee(e.email))</a>
          <td>$(ee(e.main_number))<td>$(ee(e.cell_phone))
          <td>$(join(["<span>$(ee(c))</span>" for c in e.comments]))
"""

reg_test() = begin
   io = IOBuffer()
   ob = reg_database(database)
   show(io, ob)
   return io
end


@tags html head body title dl dt dd table tr th td span

hs_database(d) = 
  html(head(title("Customers & Employees")),
    body([hs_customer(c) for c in d]...))

hs_customer(c)= 
  dl(dt("Company"), dd(c.company),
     dt("Phrase"), dd(c.phrase),
     dt("Active Since"), dd(c.active),
     dt("Employees"), dd(
       table(tr(th("Last Name"),th("First Name"),th("Title"),
                th("E-Mail"),th("Office Phone"),th("Cell Phone"),
                th("Comments")),
          [hs_employee(e) for e in c.employees]...)))

hs_employee(e) = tr(td(e.last_name), td(e.first_name), td(e.title),
                    td(href="mailto:$(e.email)", e.email),
                    td(e.main_number), td(e.cell_phone),
                    td([span(c) for c in e.comments]...))
                 
hs_test() = begin
   io = IOBuffer()
   ob = hs_database(database)
   show(io, MIME("text/html"), ob)
   return io
end

function H(xs...)
    HTML() do io
        for x in xs
            show(io, MIME"text/html"(), x)
        end
    end
end

function entity(str::AbstractString)
    @assert length(str) == 1
    entity(str[1])
end

entity(ch::Char) = "&#$(Int(ch));"

HE(x) = HTML(replace(x, r"[<&]" => entity))
HA(x) = HTML(replace(x, r"[<\"]" => entity))

#HE(x) = HTML(replace(replace(x, "&" => "&amp;"), "<" => "&lt;"))
#HA(x) = HTML(replace(replace(x, "&" => "&amp;"), "\"" => "&quot;"))

new_database(d) =
   H(HTML("<html><head><title>"), HE("Customers & Employees"),
     HTML("</title></head><body>"),
      [new_customer(c) for c in d]...,
      HTML("</body></html>"))

new_customer(c) =
   H(HTML("<dl><dt>Company<dd>"), HE(c.company), 
     HTML("<dt>Phrase<dd>"), HE(c.phrase),
     HTML("<dt>Active Siince<dd>"), HE(c.active),
     HTML("""
      <dt>Employees<dd>
        <table>
          <tr><th>Last Name<th>First Name<th>Title
              <th>E-Mail<th>Office Phone<th>Cell Phone
              <th>Comments</tr>"""),
     [new_employee(e) for e in c.employees]...,
     HTML("</table></dd></dl>"))

new_employee(e) = 
   H(HTML("<tr><td>"), HE(e.last_name), 
         HTML("<td>"), HE(e.first_name),
         HTML("<td>"), HE(e.title),
         HTML("<td><a href=\"mailto:"), HA(e.email), 
                    HTML("\">"), HE(e.email), HTML("</a>"),
         HTML("<td>"), HE(e.main_number), 
         HTML("<td>"), HE(e.cell_phone),
         HTML("<td>"),
          [H(HTML("<span>"), HE(c), HTML("</span>")) for c in e.comments]...)

new_test() = begin
   io = IOBuffer()
   ob = new_database(database)
   show(io, MIME("text/html"), ob)
   return io
end

println("interpolate: ", @benchmark reg_test())
println("Hyperscript: ", @benchmark hs_test())
println("HypertextLiteral: ", @benchmark htl_test())
println("New HTML: ", @benchmark new_test())

if false
    start = time()
    open("new.html", "w") do f
       ob = new_database(database)
       show(f, MIME("text/html"), ob)
    end
    finish = time()
    println("printing ", finish - start)
end