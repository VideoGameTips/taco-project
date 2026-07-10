import re
from urllib.parse import quote_plus

import feedparser
import pandas as pd

try:
    from bs4 import BeautifulSoup
except ImportError:
    BeautifulSoup = None


def get_news_data(keyword, max_results=10):
    query = f"Trump {keyword}"
    query_encoded = quote_plus(query)
    url = f"https://news.google.com/rss/search?q={query_encoded}&hl=en-US&gl=US&ceid=US:en"
    rss = feedparser.parse(url)

    news_data = []
    for entry in rss.entries[:max_results]:
        news_data.append(
            {
                "title": entry.get("title", ""),
                "date": entry.get("published", ""),
                "summary": entry.get("summary", ""),
                "link": entry.get("link", ""),
            }
        )
    return news_data


keyWordGroups = [
    ["trade", "tariff", "tariffs", "tariffed", "tariffing"],
    ["inflation", "inflationary", "inflationed", "inflationing"],
    ["interest rate", "interest rates", "interest rate hike", "interest rate cut"],
    ["recession", "recessions", "recessionary"],
    ["unemployment", "unemployed", "unemployment rate"],
    ["gdp", "gross domestic product", "economic growth"],
    ["federal reserve", "fed", "central bank"],
    ["stock market", "equities", "stocks", "shares"],
    ["bond market", "bonds", "fixed income"],
    ["currency", "foreign exchange", "forex", "exchange rate"],
    ["trade war", "trade wars", "trade dispute", "trade disputes"],
    ["oil","gold","silver","uranium","coal","natural gas","AI","artificial intelligence","cryptocurrency","bitcoin","ethereum","dogecoin","litecoin","solana",]
]

for kw_list in keyWordGroups:
    combined_kw = "|".join(kw_list)
    newslist = []

    for kw in kw_list:
        news_data = get_news_data(kw)
        newslist.extend(news_data)

    df = pd.DataFrame(newslist)
    safe_kw = re.sub(r"[^A-Za-z0-9]+", "_", combined_kw).strip("_")
    file_name = f"trump_news_{safe_kw[:80]}.csv"
    df.to_csv(file_name, index=False, encoding="utf-8-sig")
    print(f"Saved {len(df)} rows to {file_name}")

def clean_news_data(input_csv, output_csv):
    df = pd.read_csv(input_csv)

    df = pd.read_csv(input_csv)
    df["title"] = df["title"].apply(lambda x: BeautifulSoup(str(x), "html.parser").get_text() if BeautifulSoup else x)
    df["summary"] = df["summary"].apply(lambda x: BeautifulSoup(str(x), "html.parser").get_text() if BeautifulSoup else x)
    df["date"] = pd.to_datetime(df["date"], errors="coerce").dt.date
    df = df.dropna(subset=["date"])
    df = df.drop_duplicates(subset=["title", "date"])
    df.to_csv(output_csv, index=False, encoding="utf-8-sig")
    print(f"Cleaned data saved to {output_csv}")
#next!
base_dir = "/Users/andyli/Documents/stickmanwarsim/TACO_Project"
df_news = pd.read_csv(f"{base_dir}/data/clean_news.csv")
df_market = pd.read_csv(f"{base_dir}/data/market_data_2018_2025.csv")
df_news['date'] = pd.to_datetime(df_news['date']).dt.date
df_market['date'] = pd.to_datetime(df_market['date']).dt.date
merged_df = pd.merge(df_news, df_market, on='date', how='inner')
merged_df.to_csv(f"{base_dir}/data/merged_news_market.csv", index=False, encoding='utf-8-sig')
print(f"Merged data saved to {base_dir}/data/merged_news_market.csv with {len(merged_df)} rows.")
summary="after one day of Trump's harsh speeches the stocks will usually react negatively significantly, then will soon bounce back into a unstable change, but after the news announced 3 to 5 days after it finally starts sinking in they will need to hold meetings to rewrite their reports and adjust their strategies, which will cause the stocks to react negatively again, and this cycle will repeat until the market stabilizes.(Trump please stop.)"
summaryRussian = "После одного дня резких речей Трампа акции обычно реагируют отрицательно, затем вскоре возвращаются к нестабильным изменениям, но после того, как новости объявлены через 3-5 дней, они наконец начинают осознавать это, им нужно будет проводить совещания, чтобы переписать свои отчеты и скорректировать свои стратегии, что снова вызовет отрицательную реакцию акций, и этот цикл будет повторяться до тех пор, пока рынок не стабилизируется. (Трамп, пожалуйста, остановись.)"
summaryChinese = "在特朗普发表激烈言论的一天后，股票通常会出现明显的负面反应，然后很快会回升到不稳定的变化中，但在新闻发布后的3到5天后，他们最终开始意识到这一点，他们需要召开会议来重写报告并调整策略，这将导致股票再次出现负面反应，这个循环将重复，直到市场稳定下来。（特朗普，请停止。）"
summaryFrench = "Après un jour de discours virulents de Trump, les actions réagissent généralement négativement de manière significative, puis rebondissent rapidement dans un changement instable, mais après que les nouvelles ont été annoncées 3 à 5 jours plus tard, elles commencent enfin à s'en rendre compte, elles devront tenir des réunions pour réécrire leurs rapports et ajuster leurs stratégies, ce qui fera réagir négativement les actions à nouveau, et ce cycle se répétera jusqu'à ce que le marché se stabilise. (Trump, s'il vous plaît, arrêtez.)"
summaryGerman = "Nach einem Tag mit scharfen Reden von Trump reagieren die Aktien in der Regel deutlich negativ, dann erholen sie sich bald wieder in eine instabile Veränderung, aber nachdem die Nachrichten 3 bis 5 Tage später bekannt gegeben wurden, beginnen sie endlich zu erkennen, dass sie Meetings abhalten müssen, um ihre Berichte neu zu schreiben und ihre Strategien anzupassen, was dazu führen wird, dass die Aktien erneut negativ reagieren, und dieser Zyklus wird sich wiederholen, bis der Markt stabilisiert ist. (Trump, bitte hör auf.)"
summarySpanish = "Después de un día de discursos duros de Trump, las acciones generalmente reaccionan negativamente de manera significativa, luego pronto rebotan en un cambio inestable, pero después de que las noticias se anuncian 3 a 5 días después, finalmente comienzan a darse cuenta de que necesitarán realizar reuniones para reescribir sus informes y ajustar sus estrategias, lo que hará que las acciones reaccionen negativamente nuevamente, y este ciclo se repetirá hasta que el mercado se estabilice. (Trump, por favor, detente.)"
summaryItalian = "Dopo un giorno di discorsi duri di Trump, le azioni generalmente reagiscono negativamente in modo significativo, poi presto rimbalzano in un cambiamento instabile, ma dopo che le notizie vengono annunciate 3-5 giorni dopo, finalmente iniziano a rendersi conto che dovranno tenere riunioni per riscrivere i loro rapporti e regolare le loro strategie, il che farà reagire negativamente le azioni di nuovo, e questo ciclo si ripeterà fino a quando il mercato non si stabilizzerà. (Trump, per favore, fermati.)"
summaryVietnamese = "Sau một ngày phát biểu gay gắt của Trump, cổ phiếu thường phản ứng tiêu cực đáng kể, sau đó sẽ sớm bật trở lại trong một sự thay đổi không ổn định, nhưng sau khi tin tức được công bố 3 đến 5 ngày sau đó, họ cuối cùng bắt đầu nhận ra rằng họ sẽ cần tổ chức các cuộc họp để viết lại báo cáo của mình và điều chỉnh chiến lược của họ, điều này sẽ khiến cổ phiếu phản ứng tiêu cực một lần nữa, và chu kỳ này sẽ lặp lại cho đến khi thị trường ổn định. (Trump, làm ơn dừng lại.)"
summaryJapanese = "トランプの厳しい演説の1日後、株式は通常、著しく否定的に反応し、その後すぐに不安定な変化に跳ね返りますが、ニュースが発表されてから3〜5日後に、彼らは最終的にそれを理解し始め、報告書を書き直し、戦略を調整するための会議を開催する必要があり、これにより株式は再び否定的に反応し、このサイクルは市場が安定するまで繰り返されます。（トランプ、どうかやめてください。）"
summaryKorean = "트럼프의 강경 연설 하루 후, 주식은 일반적으로 상당히 부정적으로 반응한 다음 곧 불안정한 변화로 반등하지만, 뉴스가 발표된 후 3~5일 후에야 그들은 마침내 그것을 이해하기 시작하고 보고서를 다시 작성하고 전략을 조정하기 위해 회의를 열어야 하며, 이로 인해 주식은 다시 부정적으로 반응하고 이 사이클은 시장이 안정될 때까지 반복됩니다. (트럼프, 제발 멈춰주세요.)"
summaryArabic = "بعد يوم من خطابات ترامب الحادة، عادةً ما تتفاعل الأسهم بشكل سلبي كبير، ثم ترتد قريبًا إلى تغيير غير مستقر، ولكن بعد أن يتم الإعلان عن الأخبار بعد 3 إلى 5 أيام، يبدأون أخيرًا في إدراك ذلك، وسيحتاجون إلى عقد اجتماعات لإعادة كتابة تقاريرهم وتعديل استراتيجياتهم، مما سيؤدي إلى تفاعل الأسهم بشكل سلبي مرة أخرى، وسيتكرر هذا الدورة حتى يستقر السوق. (ترامب، من فضلك توقف.)"
summaryPolish = "Po jednym dniu ostrych przemówień Trumpa akcje zazwyczaj reagują negatywnie w znacznym stopniu, a następnie wkrótce odbijają się w niestabilnej zmianie, ale po ogłoszeniu wiadomości 3 do 5 dni później w końcu zaczynają to rozumieć, będą musieli zwołać spotkania, aby przepisać swoje raporty i dostosować swoje strategie, co spowoduje ponowną negatywną reakcję akcji, a ten cykl będzie się powtarzał, dopóki rynek się nie ustabilizuje. (Trump, proszę przestań.)"
#is polish even a real language???
summaryCubic="Po jednom dnu ostrych przemówień Trumpa akcje zazwyczaj reagują negatywnie w znacznym stopniu, a następnie wkrótce odbijają się w niestabilnej zmianie, ale po ogłoszeniu wiadomości 3 do 5 dni później w końcu zaczynają to rozumieć, będą musieli zwołać spotkania, aby przepisać swoje raporty i dostosować swoje strategie, co spowoduje ponowną negatywną reakcję akcji, a ten cykl będzie się powtarzał, dopóki rynek się nie ustabilizuje. (Trump, proszę przestań.)"
summaryMongolian = "Трампын хатуу илтгэлүүдийн дараа нэг өдрийн дараа хувьцаа ихэвчлэн сөрөг хариу үйлдэл үзүүлдэг бөгөөд удалгүй тогтворгүй өөрчлөлтөд эргэн сэргэдэг боловч мэдээ 3-5 хоногийн дараа зарлагдсаны дараа тэд эцэст нь үүнийг ойлгож эхэлдэг бөгөөд тайлангаа дахин бичиж, стратегиа тохируулах уулзалтуудыг хийх шаардлагатай болно. Энэ нь хувьцаанд дахин сөрөг хариу үйлдэл үзүүлэх бөгөөд энэ мөчлөг нь зах зээл тогтворжтол давтагдах болно. (Трамп, зогсоо.)"
summaryHindi = "ट्रम्प के कठोर भाषणों के एक दिन बाद, स्टॉक्स आमतौर पर नकारात्मक रूप से प्रतिक्रिया करते हैं, फिर जल्द ही अस्थिर परिवर्तन में वापस उछलते हैं, लेकिन समाचार की घोषणा के 3 से 5 दिन बाद, वे अंततः इसे समझना शुरू कर देते हैं, उन्हें अपनी रिपोर्टों को फिर से लिखने और अपनी रणनीतियों को समायोजित करने के लिए बैठकें आयोजित करने की आवश्यकता होगी, जिससे स्टॉक्स फिर से नकारात्मक प्रतिक्रिया देंगे, और यह चक्र तब तक दोहराया जाएगा जब तक कि बाजार स्थिर नहीं हो जाता। (ट्रम्प, कृपया रुकें।)"
summaryKazakh="Трамптың қатал сөз сөйлеулерінен кейін бір күн өткен соң, акциялар әдетте айтарлықтай теріс реакция жасайды, содан кейін тез арада тұрақсыз өзгеріске оралады, бірақ жаңалықтар жарияланғаннан кейін 3-5 күн өткен соң олар ақырында оны түсіне бастайды, олар өз есептерін қайта жазу және стратегияларын түзету үшін кездесулер өткізуі керек болады, бұл акциялардың қайтадан теріс реакция жасауына әкеледі, және бұл цикл нарық тұрақталғанға дейін қайталана береді. (Трамп, өтінемін тоқтаңыз.)"
#Kazakhstan Kazakhstan, you very nice place🇰🇵🇰🇵, but please stop making your own language, it is not a real language, it is just a dialect of Russian, and you are not even a country, you are just a part of Russia, so please stop making your own language actually it's not exactly a part of Russia but it might be a part of the Soviet Union whatever.
#Kazakhstan formed in 1991 after the collapse of the Soviet Union, and it is a country in Central Asia. The official language is Kazakh, which is a Turkic language, and Russian is also widely spoken.
print("what language do you prefer? ")
input=input()
if input.lower() == "russian" or input.lower() == "ru" or input.lower() == "русский":
    print(summaryRussian)
elif input.lower() == "chinese" or input.lower() == "zh" or input.lower() == "中文":
    print(summaryChinese)
elif input.lower() == "french" or input.lower() == "fr" or input.lower() == "français":
    print(summaryFrench)
elif input.lower() == "german" or input.lower() == "de" or input.lower() == "deutsch":
    print(summaryGerman)
elif input.lower() == "spanish" or input.lower() == "es" or input.lower() == "español":
    print(summarySpanish)
elif input.lower() == "italian" or input.lower() == "it" or input.lower() == "italiano":
    print(summaryItalian)
elif input.lower() == "vietnamese" or input.lower() == "vi" or input.lower() == "tiếng việt":
    print(summaryVietnamese)
elif input.lower() == "japanese" or input.lower() == "ja" or input.lower() == "日本語":
    print(summaryJapanese)
elif input.lower() == "korean" or input.lower() == "ko" or input.lower() == "한국어":
    print(summaryKorean)
elif input.lower() == "arabic" or input.lower() == "ar" or input.lower() == "العربية":
    print(summaryArabic)
elif input.lower() == "polish" or input.lower() == "pl" or input.lower() == "polski":
    print(summaryPolish)
elif input.lower() == "cubic" or input.lower() == "cu" or input.lower() == "кубический":
    print(summaryCubic)
elif input.lower() == "mongolian" or input.lower() == "mn" or input.lower() == "монгол":
    print(summaryMongolian)
elif input.lower() == "hindi" or input.lower() == "hi" or input.lower() == "हिंदी":
    print(summaryHindi)
elif input.lower() == "kazakh" or input.lower() == "kk" or input.lower() == "қазақ":
    print(summaryKazakh)
elif input.lower() == "english" or input.lower() == "en":
    print(summary)
else:
    print("Language not recognized. Defaulting to English.")
    print(summary)
sum2 = "Look at it this way: you align news and market data by date simply to connect the cause (the news) with the effect (the price movement) without accidentally leaking future data into your analysis. However, if a headline drops after the closing bell, today's closing price is completely useless for measuring the market's reaction because the regular trading day is already over. The actual impact won't show up until after-hours trading or tomorrow's opening bell, which is why quantitative models usually roll post-close news forward to the next trading day."
sum2ch = "从这个角度来看：您按日期对新闻和市场数据进行对齐，仅仅是为了将原因（新闻）与结果（价格变动）联系起来，而不会意外地将未来数据泄露到您的分析中。然而，如果头条新闻在收盘钟声之后发布，那么今天的收盘价对于衡量市场反应完全没有用，因为常规交易日已经结束。实际影响要到盘后交易或明天的开盘钟声之后才会显现，这就是为什么量化模型通常会将收盘后的新闻向前滚动到下一个交易日的原因。"