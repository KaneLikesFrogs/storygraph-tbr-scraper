# Storygraph TBR Scraper

This is a program I created for a friend to skim through a storygraph account export (though this should be able to be applied to goodreads files too with minimal changes)

Inside are a few different functions to perform some web scraping to get a list of books that are available on different services. Where possible I have tried to do this in paralell. 

Mainly I have tested with my own data (~40 books on tbr) and my friends data (~500 books on tbr)

Currently this is capable of performing searches on libby and on kindle unlimited and is currently setup for UK users to change this you will need to alter get_asin_url() function to instead use your local amazon URL

Below is a list of the different python libraries necesseary for this to function:

~~~

requests
random
bs4
concurrent.futures
csv
time
selenium
webdriver_manager

~~~

To use this can either just run run the libby_main() or ku_main() functions without any arguments. Alternatively can manually enter value(s) for paths to your sg export and libby library location to avoid being queried every time the function is ran

I have also added a seperate folder containing tools for comparing multiple users. This can be used for finding books that people read and agree/disagree on (based on rating). It can also be used for finding most common authors and common books on TBR lists. This is mainly intended for usage with book clubs though should work for comparing any number of users (though requires some adjusting of the queries to comment/uncomment different requests)


The following items are on the to do list : 

- Add functionality for borrow box as well
- Improve error handling throughout 
- Consider/scope out feasability of using only selenium and decide if that is more appropiate for this use case
