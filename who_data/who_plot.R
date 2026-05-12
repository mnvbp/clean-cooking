#import packages
library(tidyverse)
library(ggplot2)
library(ggthemes)

here::here()

tiff("figure1.tiff", units="in", width=7.5, height=5, res=300)

#Import CSV
data <- read.csv("data/Prop_Cleanfuel_WHO.csv", header = TRUE)

#Filter for Country
dataZambia <- data %>% 
  filter(Location == "Zambia")

#cols <- c('Urban' = '#4B9CD3', 'Rural' = '#13294B', 'Total' = '#3f647e')
cols <- c('Urban' = '#E69F00', 'Rural' = '#0072B2', 'Total' = '#009E73')
# Common theme settings
common_theme <- theme_few() +
  theme(
    text = element_text(size = 12),
    axis.title = element_text(face = "bold"),
    legend.title = element_text(face = "bold")
  )

#Plot Data + error bar + ylim
plot1 <- ggplot(dataZambia, aes(x = Period, color = Dim1)) + 
  geom_point(aes(y = FactValueNumeric, color = Dim1)) + 
  geom_line(aes(y = FactValueNumeric, color = Dim1)) + 
  ylim(0,100) +
  scale_color_manual(values= cols) +
  labs(y= "Percentage with access to clean fuels", x = "Year") + 
  guides(color = guide_legend(
    title = "Region",
    keywidth = 2,
    keyhight = 1.2
    )) +
  common_theme + 
  theme(
    legend.position = c(0.1, 0.8),
    legend.text = element_text(size = 13),   # larger legend text
    legend.title = element_text(size = 13)   # larger legend title
  )

ggplot(dataZambia, aes(x = Period, y = FactValueNumeric, color = Dim1)) +
  geom_line(linewidth = 5) +
  theme_few()

dataAfrica <- data %>% 
  filter(Dim1 == "Total") %>% filter(ParentLocationCode == "AFR")

plot2 <- ggplot(dataAfrica, aes(x = Period)) + 
  geom_line(aes(y = FactValueNumeric, color = Location)) + ylim(0,100) +
  theme(legend.position = "none")

dataWorld <- data %>% 
  filter(Dim1 == "Total")

plot3 <- ggplot(dataWorld, aes(x = Period)) + 
  geom_line(aes(y = FactValueNumeric, color = Location)) + ylim(0,100) +
  theme(legend.position = "none") +
  labs(y= "Percentage with Access to Clean Fuels", x = "Year")

plot1
#plot2
#plot3

dev.off()
