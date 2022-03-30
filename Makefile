# -----------------------------------------------------------------------------
# description: Package Configuration
# licence: LGPL3 <https://opensource.org/licenses/GPL3>
# author: Daniel Kovacs <mondomhogynincsen@gmail.com>
# version: 0.1
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# includes
# -----------------------------------------------------------------------------

include .gpf/python.mk
include .gpf/docker.mk
include ./aws-config.mk


# -----------------------------------------------------------------------------
# package config
# -----------------------------------------------------------------------------

export PACKAGE_NAME=aws-simple-auth
export PACKAGE_DECRIPTION="Simple AWS SSO Authenticator"
export PACKAGE_VERSION=1.0.0


# -----------------------------------------------------------------------------
# token
# -----------------------------------------------------------------------------

token: deps
	source ./activate && aws-simple-auth -u $(AWS_AUTH_SSO_URL) -r $(AWS_AUTH_REGION)

