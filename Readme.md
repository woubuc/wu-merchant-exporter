# Merchant Exporter

A standalone Wurm Unlimited server tool that exports a JSON file containing the location and inventory of all merchants on the server.

### Requirements

This application requires the latest [Node.js](http://nodejs.org) v4.2 LTS or higher. Tested with v5.3.0.

### Installation

Download the [latest release](https://github.com/woubuc/wu-merchant-exporter/releases) and install the dependencies using npm

    npm install


### Configuration

Configuration is located in `config.yml`. An example config file is provided, explaning the configuration variables.

### Running the program

To run the program, simply use the provided start script.

    npm start

### Known issues

- Items without a set price will have their price listed as 0