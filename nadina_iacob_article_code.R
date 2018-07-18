# ---------------------------------------------------------------------------------------- #
### ----------------------------------- nadina iacob ----------------------------------- ###
### -------------------------- web data collection - blog post ------------------------- ###
# ---------------------------------------------------------------------------------------- #


# Load packages
library(tidyverse)
library(htmlwidgets)
library(RSelenium)
library(stringr)
library(xts)
library(zoo)
library(dygraphs) # Plotting the Google Trends data
library(googleVis) # Plotting the Wikipedia page views data

# ------------------------------------------------------------------------------
# -------------------------------- Google Trends -------------------------------
# ------------------------------------------------------------------------------

### Launch Selenium driver session

### ATTENTION Line 63: German was used in this example as a browser language!

# Set the default folder for downloads.
eCaps <- list(
  chromeOptions = 
    list(prefs = list(
      "download.default_directory" = getwd()
    )
    )
)

# Initiate Selenium driver
rD <- rsDriver(extraCapabilities = eCaps)

remDr <- rD[["client"]]

# Start browser, navigate to page
url <- "https://trends.google.com/trends/"
remDr$navigate(url)


## Search for "referendum familie" (EN: referendum family)

# Identify search path
xpath <- '//*[@id="input-0"]'
searchfield <- remDr$findElement(using = 'xpath', value = xpath)
writeForm <-searchfield$sendKeysToElement(list("referendum familie"))
enterForm <-searchfield$sendKeysToElement(list(key = "enter"))


# Change time frame: between 1 May 2016 and 11 May 2018

xpath <- '//*[@id="compare-pickers-wrapper"]/div/custom-date-picker'
timeFrame <- remDr$findElement(using = 'xpath', value = xpath)
openTimeFrame <- timeFrame$clickElement() # click on button


# Customised time frame;
# !!!! Designed for a browser rendered in German; change "Benutz" to the
# correct term in the default language
xpath <- '//md-option/div[contains(text(),"Benutz")]'
timeFrameOption <- remDr$findElement(using = 'xpath', value = xpath)
openTimeFrameOption <- timeFrameOption$clickElement() 
Sys.sleep(5)

# Enter "from" date
xpath <- 
  '//div[@class="custom-date-picker-dialog-range-from"]/md-datepicker/div/input'
from <- remDr$findElement(using = 'xpath', value = xpath)
from$clearElement()
Sys.sleep(3)
from$sendKeysToElement(list("5/1/2016"))

# Enter "to" date
xpath <- 
  '//div[@class="custom-date-picker-dialog-range-to"]/md-datepicker/div/input'
to <- remDr$findElement(using = 'xpath', value = xpath)
to$clearElement() 
Sys.sleep(3)
to$sendKeysToElement(list("5/10/2018"))

# Save changes to the time frame by clicking "OK" 
ok <- remDr$findElement(using = 'xpath', 
            value = '//md-dialog-actions/button[2]')
ok$clickElement()
Sys.sleep(5)


## Search for variations: "familia traditionala" (EN: traditional family)

xpath <- 
'//*[@id="explorepage-content-header"]/explore-pills/div/button/span/span[1]'
comparefield <- remDr$findElement(using = 'xpath', value = xpath)
Sys.sleep(3)
clickfield <- comparefield$clickElement()
Sys.sleep(3)
writeForm <- comparefield$sendKeysToActiveElement(list("familia traditionala"))
enterForm <- comparefield$sendKeysToActiveElement(list(key = "enter"))


## Search for variations: "Coalitia pentru familie" (EN: Coalition for family)

xpath <- 
  '//*[@id="explorepage-content-header"]/explore-pills/div/button'
comparefield <- remDr$findElement(using = 'xpath', value = xpath)
Sys.sleep(3)
clickfield <- comparefield$clickElement()
Sys.sleep(3)
writeForm <- comparefield$sendKeysToActiveElement(list("Coalitia pentru familie"))
Sys.sleep(3)
enterForm <- comparefield$sendKeysToActiveElement(list(key = "enter"))

## Download the CSV file that contains the data on the interest in these terms over time.
# Timeline .csv
xpath <- 
  "/html/body/div[2]/div[2]/div/md-content/div/div/div[1]/trends-widget/ng-include/widget/div/div/div/widget-actions/div/button[1]"
downloadbutton <- remDr$findElement(using = 'xpath', value = xpath)
clickdown <- downloadbutton$clickElement()

# Data on countries with featured searches
xpath <- 
  "/html/body/div[2]/div[2]/div/md-content/div/div/div[2]/trends-widget/ng-include/widget/div/div/div/widget-actions/div/button[1]"
downloadbutton <- remDr$findElement(using = 'xpath', value = xpath)
clickdown <- downloadbutton$clickElement()


##  Store the live DOM tree in an HTML file on your local drive.

output <- remDr$getPageSource(header = TRUE)
write(output[[1]], file = "google_trends_data_science.html")

## Close connection
remDr$closeServer()



## Parse data and transform it into xts format for dygraph
filenames <- list.files(full.names = TRUE) %>% str_extract(".*csv")
filenames
df <- read_csv("multiTimeline.csv", skip = 2)
str(df)
names(df) <-  c("week", "referendum_familie", "familia_traditionala", "coalitia_pentru_familie")

x <- xts(df$referendum_familie, df$week)
y <- xts(df$familia_traditionala, df$week)
z <- xts(df$Coalitia_pentru_familie, df$week)
google_trends <- cbind(x, y, z)


# Create dataframe with the most significant events related to the topic

dates <- c("2016-5-22",
           "2016-9-25",
           "2016-10-16",
           "2016-11-6",
           "2016-11-13",
           "2016-12-11",
           "2017-3-26",
           "2017-5-7",
           "2017-5-14",
           "2017-6-4",
           "2017-9-3",
           "2018-3-25",
           "2018-4-15",
           "2018-4-29")
descr <- c("23 May 2016: Legislative proposal and 3M signatures handed in to the Senate",
           "26 Sep 2016: Coaliția pentru Familie requests Parliament vote on the proposal by mid-October for the referendum to take place at the same time as general elections in December",
           "19/21 Oct 2016: Romanian President calls for tolerance instead of religious fanatism. PSD Leader reacts in support of the traditional family referendum",
           "11 Nov 2016: PSD Leader - The referendum to decide on the proposed changes to the Constitution should take place in spring 2017 at the latest",
           "19 Nov 2016 - March in Bucharest against the proposal to modify the definition of the family in the Constitution",
           "11 Dec 2016: General elections in Romania",
           "27 Mar 2017: The Chamber of Deputies votes on the articles of the proposed constitutional change and adopts them without further amendments; Final vote to come",
           "9 May 2017: Chamber of Deputies adopts the proposal. The Constitutional change must be, however, voted on in a referendum for it to become official.",
           "14-20 May 2017: Bucharest Pride, organised by the ACCEPT organisation. 20 May: Counter manifestation organised by Coaliția pentru Familie.",
           "7 June 2017: 100 NGOs, civic movements, and citizens form the civic platform RESPECT, in reaction to the referendum for the traditional family.",
           "2-3 Sep 2017: PSD Leader - There is agreement within the party as well as the government that the referendum should take place this autumn.",
           "26 Mar 2018: PSD - The referendum could take place in May 2018.",
           "16 Apr 2018: At the suggestion of its leader, PSD adopts a decision to organise a 1-million-people manifestation in support of the traditional family referendum",
           "3 May 2018: Vicepresident of the Chamber of Deputies and PSD member - The referendum could be organised on 10 June 2018.")
texts <- rep("!", length(dates))
events <-  data.frame(dates, descr, texts)



## Plot data and save as HTML file
graph <- 
  dygraph(google_trends, 
          main = "")  %>% 
  dyRangeSelector() %>% 
  dyHighlight(highlightSeriesOpts = list(strokeWidth = 3)) %>% 
  dySeries("..1", label = "referendum familie") %>% 
  dySeries("..2", label = "familia traditionala") %>% 
  dySeries("..3", label = "coalitia pentru familie") %>% 
  dyAxis("y", valueRange = c(0, 120)) %>% 
  dyLegend(show = "always", hideOnMouseOut = FALSE) %>% 
  dyLegend(width = 600) %>% 
  dyOptions(includeZero = TRUE, 
            axisLineColor = "grey", 
            drawGrid = FALSE,
            colors = c("#4da16c", "#f29f33", "#b0467d"))

  
my_code<-paste("graph %>%",
               paste0("dyAnnotation('",dates,"', text='", texts, "',
                      tooltip='", descr, "')",collapse = " %>% "))

graph_final <- eval(parse(text = my_code))

saveWidget(graph_final, file = "google_trends.html")



# -------------------------------- Wikipedia API -------------------------------


## Load packages
library(WikipediR)
library(pageviews)


## Retrieve page views from the 4 main webpages related to the topic:
# 1. The Wikipedia page dedicated to the traditional family referendum (in Romanian)
referendum_ro_views <- article_pageviews(project = "ro.wikipedia", 
                                      article = "Inițiativa_de_modificare_a_articolului_48_din_Constituția_României", 
                                      user_type = "user", start = "2016050100", end = "2018051000")

# 2. The Wikipedia page dedicated to the traditional family referendum (in English)
referendum_en_views <- article_pageviews(project = "en.wikipedia", 
                                      article = "Romanian_constitutional_referendum,_2018", 
                                      user_type = "user", start = "2016050100", end = "2018051000")

# 3. The Wikipedia page dedicated to the main supporter of the referendum (in Romanian)
cfp_ro_views <- article_pageviews(project = "ro.wikipedia", 
                                      article = "Coaliția_pentru_Familie", 
                                      user_type = "user", start = "2016050100", end = "2018051000")

# 4. The Wikipedia page dedicated to the main supporter of the referendum (in English)
cfp_en_views <- article_pageviews(project = "en.wikipedia", 
                                  article = "Coaliția_pentru_Familie", 
                                  user_type = "user", start = "2016050100", end = "2018051000")

# Plot data using the googleVis package; plot 1 and 2 are of interest since they have the 
# highest number of page views.
plot1 <- 
  gvisCalendar(
    data=cfp_en_views, 
    datevar="date", 
    numvar="views", 
    options=list(
      title="CpF (EN) - Daily page views",
      titleTextStyle="{fontSize:20}",
      width='100%',
      height='100%',
      calendar="{yearLabel: {fontSize: 20, color: 'grey', bold: true},
      focusedCellColor: {stroke:'#962071'}}"
    ), 
    chartid="Calendar"
  )


cat(plot1$html$chart, file = "cfp_en_views.html")


plot2 <- 
  gvisCalendar(
    data=referendum_ro_views,  
    datevar="date", 
    numvar="views", 
    options=list(
      width='100%',
      height='100%',
      title="Referendum (RO) - daily page views",
      calendar="{yearLabel: {fontSize: 25px, color: 'grey', bold: true},
      focusedCellColor: {stroke:'#962071'}}"),
    chartid="Calendar"
  )


cat(plot2$html$chart, file = "referendum_ro_views.html")


plot3 <- 
  gvisCalendar(
    data=referendum_en_views, 
    datevar="date", 
    numvar="views", 
    options=list(
      width='100%',
      title="Referendum (EN) - daily page views",
      calendar="{yearLabel: {fontSize: 20, color: 'grey', bold: true},
      focusedCellColor: {stroke:'#962071'}}"
    ), 
    chartid="Calendar"
  )


cat(plot3$html$chart, file = "referendum_en_views.html")


# Explore the history of page changes
changes_en <-  recent_changes("en","wikipedia", page = "CoaliÈia_pentru_Familie")
changes_ro <-  recent_changes("ro","wikipedia", page = "CoaliÈia_pentru_Familie")
changes_ro <- unlist(changes_ro$query["recentchanges"])
changes[1:20]


