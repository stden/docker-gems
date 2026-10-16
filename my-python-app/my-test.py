#!/usr/bin/env python3
# Import the necessary libraries.
import os

import mysql.connector as db
import requests


# Check the web page status.
def check_website(url):
    try:
        response = requests.get(url)  # Send a GET request.
        # Print the response status code.
        print(f'Response status code for {url}: {response.status_code}')
        assert response.status_code == 200, 'Expected HTTP 200'
    except requests.exceptions.RequestException as e:
        # If the request fails, print a message.
        print(f'Request to {url} failed: {e}')


def my_db():
    print('Connect to the database')
    mydb = db.connect(
        host=os.getenv('DB_HOST'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        database=os.getenv('DB_NAME'),
    )

    cur = mydb.cursor()
    print(f"Database cursor: {cur}")
    cur.execute("SELECT * FROM user")
    r = cur.fetchall()
    for row in r:
        print(row)


# Start the program.
if __name__ == '__main__':
    print('Hello from Docker! Well done!')
    # Set the URL to check.
    test_url = 'https://www.google.com'
    # Check the web page.
    check_website(test_url)
    my_db()
