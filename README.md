## About The Project

This project is a coding challenge from an unnamed (to prevent this repo from being found for future hiring) price transparency company. The challenge was to read a [TOC File](https://github.com/CMSgov/price-transparency-guide/tree/master/schemas/table-of-contents) from Anthem Health and parse out specific location URLs that matched a given state (in this case - this script is hard coded to look for New York IDs).

<!-- GETTING STARTED -->
## Getting Started

This project was written in Swift, using vanilla swift 5.10.

<!-- USAGE EXAMPLES -->
## Usage

To run this project, ensure you have swift 5.10 installed (other 5.x versions should generally also work) and run `swift run url-gen <URI-to-uncompressed-TOC-file>`. The script will output a list of URLs to either `In Network File` locations or `Allowed Amount File` locations that match the slug used for NY State codes (program could easily be extended to accept other state codes). If you desire the URLs to be written to a file, simply pipe the output to grep on `http` and redirect the output to a file. This script could obviously be extended to write URLs to a file directly, but as a POC, I feel this grep and redirect solution works well. Additionally, this program will print lines in which the JSON can't be parsed.

## Discussion

The challenges here revolved around
* Reading a very large TOC file (22.65 Gb for June 2024's TOC file)
  * I dealt with this by reading the file line by line. Since each line is its own `Reporting Structure` JSON object in a larger `reporting_structure` JSON array, we can do this by removing the trailing `,` and parsing it as a standalone JSON object.
* Determining how to find URLs for a specific state.
  * I was able to determine which URLs matched New York by searching an EIN on [Anthem's Machine Readable File Search](https://www.anthem.com/machine-readable-file/search/) site, which lists the URLs with a 2-character state code followed by a 4 character (hex?) code. Using this 4 character code, I was able to map it to URLs in the TOC file. While I only did this for New York, and checked a single EIN for this example project, it would be trivial to create this mapping for other states as well. My concern is that this is not an exhaustive list and it may not map to only PPOs specifically... if there's a trick there, I haven't found it yet.
  * It would be tempting to have used the `description` field, however the names were often incomplete or lacking a state name entirely
* Lots of the URLs are duplicates, so determining how to de-dupe effectively was important. For this I used a dictionary and set the key to the full location. Pretty dirty hack but it works. I de-duped before checking for the state code, because this meant we had to check a lot fewer strings.
* Since these URLs are signed, there's lots of opportunities for strings to match some random substring in the signature. Since `_` is not allowed in the signature, and both started and ended the state code, I was able to search for instances of `_<code>_`. I also trimmed the URLs so most of the expires and signature fields would be dropped (and it would reduce our search space significantly)

I spent around 30 minutes looking at the TOC file just trying to wrap my head around the data structure and trying to find the pattern to identify files for a given state. It also took me a bit of time to find the TOC file to begin with (the file linked in the challenge README is no longer available, but I deduced the naming convention of the TOC file and was able to grab the current month's file instead)

I spent perhaps 45 minutes writing this swift script. I had [previously written a large-file-parser](https://github.com/kecramer/front-topk) in swift that I was able to borrow some code from which helped speed this up. Additionally, since swift parses JSON into well-defined `structs`, having the JSON schema available helped speed up how quickly I could get the JSON to parse.

Finally, when I realized there might be multiple state codes for a given state, I spent maybe another 30 minutes trying to figure out how to deal with that. This was easy enough in code, but it meant I was doing significantly more checks for substring-in-string, so I tried to clean up some of the logic, and it also made me a bit uncertain that I was capturing ALL of the New York PPO files. I think I'd like to make this program parse ALL the file-locations, print out a full list of all state codes (+4 digit hex?) and make a full mapping. Since only a single month is available, I'm not sure if these are fixed or change from month-to-month.

I had to work around getting the house ready for some family guests we are expecting next week, so I had to leave and come-back to this work a few times. Ultimately this made the work feel a little dirty as my thoughts jumped around, but I think the resulting code is clean-enough for a quick project. The major tradeoffs I made in the interest of time were to
* Simply ignore lines that did not parse into a valid JSON object as defined in my swift structs
* Only output URLs to stdout, each on their own line, and using bash redirection to put the result in a file
* Not really working too hard to optimize the computational portion of this code as I made the assumption that disk I/O would likely be the limiting factor in the script's performance
* Only creating a mapping for NY State file slugs. Ideally I'd map all the states and record slugs I don't recognize so that I could look up which state they belong to.

## Timing

When run as a debugging build, this takes around 2 minutes to process the full June TOC file on my MacBook Pro M1.

```
$ time swift run url-gen ~/Downloads/2024-06-01_anthem_index.json | grep "http" > urls.txt
Building for debugging...
[1/1] Write swift-version--58304C5D6DBC2206.txt
Build complete! (0.09s)

real    1m47.942s
user    1m36.242s
sys     0m8.984s```