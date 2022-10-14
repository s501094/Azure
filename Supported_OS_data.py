##
# Creator: Tyler Ellis
# Date: 10/13/22
# Description: Pull supported Images list for Update Management Center Preview from Microsoft Documentation
##
 
from msilib import Table
import os
from wsgiref import headers
import requests
from bs4 import BeautifulSoup
import pandas as pd

# url of supported images
url = 'https://learn.microsoft.com/en-us/azure/virtual-machines/automatic-vm-guest-patching#supported-os-images'

# using request to pull page information
page = requests.get(url)


# create directory to store file in
directory_name = "UMC"

# parent directory for folder
parent_dir = "C:\\"

# path
path = os.path.join(parent_dir, directory_name)

# create directory
os.mkdir(path)

# breaking the pulled infromation into BeatifulSoup readable format
soup = BeautifulSoup(page.text, 'lxml')
# locating the table with information from lxml content
table1 = soup.find("table")
# creating headers list and pulling the table title headers out from the html and appending them to list
headers = []
for i in table1.find_all('th'):
    title = i.text
    headers.append(title)

# creating table dataframe in pandas with headers as columns
mydata = pd.DataFrame(columns=headers)

# looping through each table data and appending them to the dataframe 
for j in table1.find_all('tr')[1:]:
    row_data = j.find_all('td')
    row = [i.text for i in row_data]
    length = len(mydata)
    mydata.loc[length] = row

# writing table information to cxv file
mydata.to_csv(os.path.join(path,r'Supported_OS_data.csv'), index=False)
