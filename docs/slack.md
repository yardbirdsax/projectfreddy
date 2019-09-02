# Adding Slack Notifications

This document includes instructions on how to set up Slack notifications for alerts.

## Installing the Slack Webhook App

1. Make sure you are signed in to your Slack workspace.
1. Go to https://slack.com/apps/A0F7XDUAZ-incoming-webhooks and install the app.
1. Select the channel that the alerts will post to.
1. Copy the URL for the webhook to the clipboard.

## Setting up Alertmanager

1. In the `values.yaml` file, edit the entry under the "alertManagerFiles" -> "alertmanager.yml" -> "receivers" section, similar to the below.

    ```yaml
    - name: slack
      slack_configs:
      - channel: 'slack channel'
        send_resolved: true
        api_url: "slack url"
    ```