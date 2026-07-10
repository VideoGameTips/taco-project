import feedparser
import pandas as pd
from pathlib import Path
from urllib.parse import quote_plus
from datetime import datetime

def fetch_news_by_keywords(keywords, max_results=15):
    """
    Fetch news articles from Google News based on the provided keywords.

    Parameters:
    - keywords: A string of keywords to search for.
    - max_results: Maximum number of news articles to fetch.

    Returns:
    - A pandas DataFrame containing the news articles.
    """
    # Encode the keywords for URL
    encoded_keywords = quote_plus(keywords)


    # Construct the Google News RSS feed URL
    rss_url = f"https://news.google.com/rss/search?q={encoded_keywords}&hl=en-US&gl=US&ceid=US:en"
    print("enter keywords:")

    # Parse the RSS feed
    feed = feedparser.parse(rss_url)
    # Extract relevant information from the feed entries
    news_data = []
    for entry in feed.entries[:max_results]:
        news_data.append({
            'title': entry.title,
            'link': entry.link,
            'published': datetime(*entry.published_parsed[:6]),
            'summary': entry.summary
        })
    if not news_data:
        print("No news articles found for the given keywords.")
    elif len(news_data) < max_results:
        print(f"Only {len(news_data)} articles found for the given keywords.")
    else:
        print(f"Fetched {len(news_data)} articles for the given keywords.")

    # Convert to DataFrame
    news_df = pd.DataFrame(news_data)

    return news_df