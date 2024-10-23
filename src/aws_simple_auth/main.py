import os
import time
from datetime import datetime, timedelta

from . import cli
from .aws_sso_menu import show_menu
from .retrieve_aws_sso_token import retrieve_aws_sso_token

SSO_TOKEN_TIMEOUT = timedelta(hours=8)


def main(args):
    aws_sso_token = None
    aws_sso_token_reused = False
    if os.path.isfile(args.output_file):
        aws_sso_token_age = datetime.now() - datetime.fromtimestamp(os.path.getmtime(args.output_file))
        print(f"Found AWS SSO Token in file: {args.output_file}, and it is {aws_sso_token_age} old.")
        if aws_sso_token_age <= SSO_TOKEN_TIMEOUT:
            with open(args.output_file, "r") as f:
                aws_sso_token = f.read()
                aws_sso_token_reused = True
        else:
            print(f"AWS Token file: {args.output_file} is older than {SSO_TOKEN_TIMEOUT}, requesting a new one...")
    if not aws_sso_token:
        aws_sso_token = retrieve_aws_sso_token(args)

    if args.output_file and not aws_sso_token_reused:
        with open(args.output_file, "w") as f:
            f.write(aws_sso_token)
            print(f"Wrote the AWS SSO token to {args.output_file}")

    while True:
        show_menu(aws_sso_token, args.region)
        print("You can keep creating more tokens, or press CTRL+C to exit.")


def cli_menu():
    main(cli.parser.parse_args())
