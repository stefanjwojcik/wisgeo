
using RCall
using Luxor

############# state polygons 
R""" 
library(spData)
data(us_states)
geos = us_states$geometry
"""

us_states = rcopy(@rget geos)

# Create function to unpack the polygons from R object 
get_poly_points = function(rob)
   unpacked = vcat([collect(Iterators.flatten(x)) for x in rob]...)
   unpacked_points = [Point.(Tuple.(eachrow(x))) for x in unpacked]
   out = []
   for i in unpacked_points
      hi = [x * (-1, 1) for x in i]
      push!(out, hi)
   end
   return out
end

mypoints = get_poly_points(us_states);

@png begin
   setopacity(.6)
   background("black")
   rotate(π)
   scale(10)
   sethue("antiquewhite")
   #poly.(unpa1cked_points, :stroke, close=true)
   translate(-95, -40)
   poly.(mypoints, :stroke, close=false)
end

# This is the core 80's image of the US
 
## This one shows varying 'heights'
@png begin
   setopacity(.6)
   background("black")
   rotate(π)
   scale(10)
   sethue("antiquewhite")
   #poly.(unpa1cked_points, :stroke, close=true)
   translate(-92, -40)
   for state in mypoints
      randomhue()
      for i in .95:.01:.99
         if true
            poly(state.-i, :fill, close=true)
         end
      end
   end
end 700 400 "/home/swojcik/Downloads/myus.png"

#####*********]

############# state polygons 
R""" 
library(spData)
data(us_states)
geos = us_states[]$geometry
"""

@png poly.(mypoints, :stroke)

california = us_states[27][1][1]

alabama = us_states[1][1][1]
ala_points = Point.(Tuple.(eachrow(alabama)))
@png poly(ala_points, :stroke)
@png ngon(0, 0, 4, 4, 0, :close)
@png poly.(mypoints, :stroke)


@png ngon(0, 0, 4, 4, 0, :stroke)


@png begin
   text("WTF")
   sethue("orchid4")
   ngon(0, 0, 60, 6, 0, :stroke)
end


@png begin
   text("Hello world")
   circle(Point(0, 0), 200, :stroke)
   rulers()
   line(Point(0, 0), Point(200, 200), :stroke)
end

####### County Polygons 
using JSON
using Luxor

counties = JSON.parsefile("/home/swojcik/Downloads/us-county-boundaries.json")

# Function flattens until an array is the lowest level type  
# so that each element is an x,y array
function specific_flatten(a::AbstractArray)
   while any(x->typeof(x[1])<:AbstractArray, a)
       a = collect(Iterators.flatten(a))
   end
   return a
end

# how to unparse the counties 
parse_counties = function(jsonfile)
   out = []
   for county in jsonfile
      array_of_points = [Point(x,y) for (x,y) in specific_flatten(county["fields"]["geo_shape"]["coordinates"])]
      #reverse the x value to get the mirror image 
      array_of_points .= [x * (-1, 1) for x in array_of_points]
      name_of_county = county["fields"]["name"]
      push!(out, array_of_points)
   end
   return out
end

mich = parse_counties(filter(x-> x["fields"]["state_name"]=="Michigan", counties));
wisc = parse_counties(filter(x-> x["fields"]["state_name"]=="Wisconsin", counties));
door = parse_counties(filter(x-> x["fields"]["name"] == "Door", counties))

counties_as_points = parse_counties(counties)
@png poly.(wisc, :stroke)

# Wiconsin centered
@png begin
   setopacity(.6)
   background("black")
   rotate(π)
   scale(50)
   sethue("antiquewhite")
   #translate(-90, -45)
   poly.(wisc, :stroke, close=false)
end

# ******
out = []
counties = JSON.parsefile("/home/swojcik/Downloads/us-county-boundaries.json")
for county in counties
   println(county["fields"]["name"])
   array_of_points = [Point(x,y) for (x,y) in specific_flatten(county["fields"]["geo_shape"]["coordinates"])]
   push!(out, array_of_points)
end
# mycounty is problematic, othercounty works 
mycounty = filter(x-> x["fields"]["name"]=="Weld", counties)[1]
othercounty = filter(x-> x["fields"]["name"]=="Orange", counties)[1]