import boto3
import logging
import json

LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)


def process_event(event):
    data = {}
    for i in event['Records']:
        if i['eventName'] == 'MODIFY' and i['eventSource'] == 'aws:dynamodb':
            data = i['dynamodb']['NewImage']
    return data


def send_message(data):

    message_default = '''
{:20}{}
{:20}{}
{:20}{}
{:20}{}
{:20}

{}
    '''.format('Package: ',
               data['Package']['S'],
               'Version: ',
               data['Version']['S'],
               'Update Type: ',
               data['UpdateType']['S'],
               'Release Notes Url: ',
               data['Url']['S'],
               'Release notes:',
               data['ReleaseNotes']['S'])

    message_sms = '''
PACKAGE UPDATE

Package:     {}
Version:     {}
Update Type: {}
Release Notes Url:
{}
    '''.format(data['Package']['S'],
               data['Version']['S'],
               data['UpdateType']['S'],
               data['Url']['S'])
    message = {
        "default": message_default,
        "email": message_default,
        "sms": message_sms,
    }
    client = boto3.client('sns')
    client.publish(
        TopicArn='arn:aws:sns:eu-west-2:936009664337:package-update',
        MessageStructure='json',
        Message=json.dumps(message),
        Subject='New Package Release: {} - v{}'.format(data['Package']['S'], data['Version']['S']),
    )


def lambda_handler(event, context):
    """
    Main function called by lambda
    """
    data = process_event(event)
    if data:
        send_message(data)
    else:
        LOGGER.critical("No matching data found for the event")


if __name__ == "__main__":
    lambda_handler("", "")
