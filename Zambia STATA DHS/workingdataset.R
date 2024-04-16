#import packages
library(tidyverse)
library(ggplot2)
library(tidyr)

setwd("~/manav-workspace/clean_cooking/Zambia STATA DHS")


data <- read.delim("finaldata9_23.csv", header = TRUE, sep=",")

df <- subset(data, select= c(wealth, dhsclust, close_dist, 
                             v161, v457, v106, m19, weight_card, v456))

prop_dist <- function(d, a, b, c) {
  df_grouped <- d %>% group_by({{a}},{{b}},{{c}}) %>% tally()
  df_sum <- df_grouped %>% group_by({{a}}, n) %>% tally()
}

df_grouped <- prop_dist(df, wealth, dhsclust, close_dist)

eq <- function(x,y) {
  m <- lm(y ~ x)
  as.character(
    as.expression(
      substitute(italic(y) == a + b %.% italic(x)*","~~italic(r)^2~"="~r2,
                 list(a = format(coef(m)[1], digits = 4),
                      b = format(coef(m)[2], digits = 4),
                      r2 = format(summary(m)$r.squared, digits = 3)))
    )
  )
}
#proportion of wealth per cluster
datatally <- data %>% group_by(wealth, dhsclust, close_dist) %>% tally()
sums <- aggregate(n ~ dhsclust, data=datatally, sum)
sums <- rename(sums, "sum" = n)
datatally <- merge(datatally, sums)
datatally$proportion <- datatally$n / datatally$sum
ggplot(datatally, aes(close_dist, proportion, color = wealth)) + geom_point() + geom_smooth(method='lm', se=FALSE) +  geom_text(x = 2, y = 1, label = eq(df$wt,df$hp), parse = TRUE)

#proportion fuel per cluste
datafuel <- data %>% group_by(v161, dhsclust, close_dist) %>% tally()
sumsfuel <- aggregate(n ~ dhsclust, data=datafuel, sum)
sumsfuel <- rename(sumsfuel, "sum" = n)
datafuel <- merge(datafuel, sumsfuel)
datafuel$proportion <- datafuel$n / datafuel$sum
ggplot(datafuel, aes(close_dist, proportion, color = v161)) + geom_point() + facet_wrap(~v161) + geom_smooth(method='lm')

#proportion anemic vs distance
dataanem <- data %>% group_by(v457, dhsclust, close_dist) %>% tally()
sumsanem <- aggregate(n ~ dhsclust, data=dataanem, sum)
sumsanem <- rename(sumsanem, "sum" = n)
dataanem <- merge(dataanem, sumsanem)
dataanem$proportion <- dataanem$n / dataanem$sum
ggplot(dataanem, aes(close_dist, proportion, color = v457)) + geom_point() + facet_wrap(~v457) + geom_smooth(method='lm')



#proportion education vs distance
dataedu <- data %>% group_by(v106, dhsclust, close_dist) %>% tally()
sumsedu <- aggregate(n ~ dhsclust, data=dataedu, sum)
sumsedu <- rename(sumsedu, "sum" = n)
dataedu <- merge(dataedu, sumsedu)
dataedu$proportion <- dataedu$n / dataedu$sum
ggplot(dataedu, aes(close_dist, proportion, color = v106)) + geom_point() + facet_wrap(~v106) + geom_smooth(method='lm')



ggplot(data,aes(close_dist, v456)) + geom_point() + geom_smooth(method='lm')
ggplot(data,aes(close_dist, m19)) + geom_point()
ggplot(data,aes(close_dist, weight_card)) + geom_point() +geom_smooth(method='lm')


