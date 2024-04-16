#import packages
library(tidyverse)
library(ggplot2)
library(ggthemes)

setwd("/Users/manavparikh/manav-workspace/clean_cooking/WHO data (R)") 

#Import CSV
data <- read.csv("Prop_Cleanfuel_WHO.csv", header = TRUE)

#Filter for Country
dataZambia <- data %>% 
  filter(Location == "Zambia")

cols <- c('Urban' = '#4B9CD3', 'Rural' = '#13294B', 'Total' = '#3f647e')

#Plot Data + error bar + ylim
plot1 <- ggplot(dataZambia, aes(x = Period), color = Dim1) + 
  geom_point(aes(y = FactValueNumeric, color = Dim1)) + 
  geom_line(aesy = FactValueNumeric, color = Dim1) + 
  ylim(0,100) +
  scale_color_manual(values= cols) +
  labs(y= "Percentage with Access to Clean Fuels", x = "Year") + 
  guides(color = guide_legend(title = "Region")) +
  theme_few() + 
  theme(legend.position = c(0.1, 0.8)) 

dataAfrica <- data %>% 
  filter(Dim1 == "Total") %>% filter(ParentLocationCode == "EUR")

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
plot2
plot3
