#! /usr/bin/env python3

import logging
import re
import json
import os
import requests
import boto3
from bs4 import BeautifulSoup
from packaging.version import parse

DYNAMO_TABLE = os.environ.get("DYNAMO_TABLE")


def return_releases_html():
    """
    Retrieves and returns all the html for the terraform releases page
    """
    response = requests.get("https://releases.hashicorp.com/terraform/")

    if response.status_code != 200:
        print("Failed to retrieve release data from terraform")
        exit(1)
    else:
        return response.text


def return_release_list(html_doc):
    """
    Returns a list of all Terraform versions derrived
    from the terraform releases page
    """
    releases = []
    soup = BeautifulSoup(html_doc, 'html.parser')
    for i in soup.find_all('a'):
        releases.append(i.text.replace('terraform_', ''))
    releases = releases[1:]
    return releases


def filter_releases(releases):
    """
    Filters list of releases to remove ignored releases rc/beta/alpha
    """
    filters = ["rc", "beta", "alpha"]
    unwanted = []
    for i in filters:
        for x in releases:
            if i in x:
                unwanted.append(x)
    filtered_releases = [x for x in releases if x not in unwanted]
    return filtered_releases


def get_release_notes_and_url(release):
    """
    Returns release notes for given release and url
    """
    release = parse(release)
    url = "https://raw.githubusercontent.com/hashicorp/terraform/v{}.{}/CHANGE\
LOG.md".format(release.major, release.minor)
    response = requests.get(url)
    if response.status_code != 200:
        logging.critical("Failed to retrieve release note")
        exit(1)
    else:
        m = re.search('##\s+{}(?:.*\n)+?(?=##)'.format(release),
                      response.text, re.MULTILINE)
        if m:
            return m.group(), url
        else:
            return "", url


def check_version(previous, current):
    """
    Compares versions and returns update type (patch,minor,major)
    """
    previous = parse(previous)
    current = parse(current)
    if previous == current:
        logging.debug("No Version Change")
        return None
    elif previous > current:
        logging.critical("Previous version is newer than latest")
        exit(1)
    else:
        update = ""
        if current.micro > previous.micro:
            update = "patch"
        if current.minor > previous.minor:
            update = "minor"
        if current.major > previous.major:
            update = "major"
        return update


def get_previous_version():
    """
    Retreives last logged version from dynamodb
    """
    client = boto3.client('dynamodb')
    response = client.get_item(TableName=DYNAMO_TABLE,
                               Key={"Package": {"S": "terraform"}})
    if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        logging.critical("Unable to retrieve state from dynamodb, \
        see response data: {}".format(response['ResponseMetadata']))
        exit(1)
    if 'Item' in response:
        version = response['Item']['Version']['S']
    else:
        version = "0.0.0"
    return version


def store_latest_version(current, release_notes, url, update_type):
    """
    Stores latest version found in dynamodb
    """
    client = boto3.client('dynamodb')
    response = client.put_item(TableName=DYNAMO_TABLE,
                               Item={"Package": {"S": "terraform"},
                                     "Version": {"S": current},
                                     "ReleaseNotes": {"S": release_notes},
                                     "Url": {"S": url},
                                     "UpdateType": {"S": update_type}})
    if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        logging.critical("Unable to store state on dynamodb, \
            see response data: {}".format(response['ResponseMetadata']))
        exit(1)


def lambda_handler(event, context):
    """
    Main function called by lambda
    """
    n = int(os.getenv("RELEASE_OFFSET", default=0))
    html_doc = return_releases_html()
    releases_list = return_release_list(html_doc)
    releases_list = filter_releases(releases_list)

    current = releases_list[n]
    previous = get_previous_version()
    update = check_version(previous, current)
    if update:
        release_notes, url = get_release_notes_and_url(current)
        store_latest_version(current, release_notes, url, update)
        return {
            'statusCode': 200,
            'body': json.dumps('New terraform release recorded')
        }
    else:
        return {
            'statusCode': 200,
            'body': json.dumps('No new release recorded')
        }


if __name__ == "__main__":
    lambda_handler("", "")
