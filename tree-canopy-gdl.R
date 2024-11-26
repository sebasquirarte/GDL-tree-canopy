# Tree Canopy Interactive Map of Guadalajara, Jalisco, México
# Sebastian Quirarte Justo | sebastianquirajus@outlook.com | Nov 2024

# Inspired by Milos Agathon (Milos Makes Maps). Check out his work at: 
# https://github.com/milos-agathon/tree-height-maps-meta?tab=readme-ov-file
# https://www.youtube.com/@milos-makes-maps

# Packages ----

install.packages("pak")
install.packages("pacman")

pak::pkg_install("TESS-Laboratory/chmloader")
pak::pkg_install("rstudio/leaflet")

pacman::p_load(chmloader,
               terra,
               sf,
               maptiles,
               classInt,
               tidyverse,
               tidyterra,
               leaflet,
               htmlwidgets,
               ggplot2)

# Buffer ----

# Coordinates
lat <- 20.6769938
long <- -103.3461715

city_coords <- sf::st_point(c(long, lat)) |>
               sf::st_sfc(crs = 4326) |>
               sf::st_buffer(dist = units::set_units(2, km))

# Tree Height Data ----

city_chm <- chmloader::download_chm(city_coords,
                                    filename = "gdl-chm.tif")

city_chm_new <- terra::ifel(city_chm == 0,
                            NA,
                            city_chm)

terra::plot(city_chm_new,
            col = hcl.colors(64, "viridis"))

# Street Tiles ----

city_bbox <- sf::st_bbox(city_coords)

streets <- maptiles::get_tiles(city_bbox,
                               provider = "CartoDB.DarkMatter",
                               zoom = 15,
                               crop = TRUE,
                               project = FALSE)

terra::plotRGB(streets)

# Raster to Dataframe ----

city_chm_df <- as.data.frame(city_chm_new,
                             xy = TRUE)

names(city_chm_df)[3] <- "chm"

# Breaks and Color Palette ----

breaks <- classInt::classIntervals(var = city_chm_df$chm,
                                   n = 6,
                                   style = "equal")$brks

colors <- hcl.colors(length(breaks),
                     "ag_GrnYl",
                     rev = FALSE)

# Map ----

map <- ggplot(city_chm_df) + 
       tidyterra::geom_spatraster_rgb(data = streets,
                                      maxcell = 3e6) +
       geom_raster(aes(x = x, 
                       y = y,
                       fill = chm)) +
       scale_fill_gradientn(name = "canopy height (m)",
                            colors = colors,
                            breaks = breaks,
                            labels = round(breaks, 0)) +
       guides(fill = guide_colorbar(direction = "horizontal",
                                    barheight = unit(2, units = "mm"),
                                    barwidth = unit(30, units = "mm"),
                                    title.position = "top",
                                    label.position = "bottom",
                                    title.hjust = .5,
                                    label.hjust = .5)) +
       theme_void() +
       theme(legend.position = "top",
             legend.title = element_text(size = 11, 
                                         color = "white"),
             legend.text = element_text(size = 10, 
                                        color = "white"),
             legend.background = element_rect(fill = "black", color = NA),
             plot.margin = unit(c(t = .2, r = -1, b = -1, l = -1), "cm"))

ggsave("gdl-tree-height.png",
       map,
       width = 7,
       height =7,
       units = "in",
       bg = "black")

# Interactive Map ----

map_interactive <- terra::plet(x = city_chm_new,
                               col = colors,
                               alpha = 1,
                               tiles = "Streets",
                               maxcell = 3e6,
                               legend = "topright")

htmlwidgets::saveWidget(map_interactive,
                        file = "gdl-chm.html",
                        selfcontained = FALSE)