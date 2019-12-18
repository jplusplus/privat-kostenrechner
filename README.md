# Total cost of ownership calculator

## Description

Of the 1.9 million cars that are newly registered by companies in Germany every year, approximately 800,000 are part of company fleets. There lies the great potential for electromobility. Compared to the private use of electric vehicles company fleets offer advantages. The limited range is less of a problem when one has access to a pool of vehicles. The set up and use of charging options on company premises tends to be easier, too. Regular and planned use of electric vehicles could avoid usage conflicts and increase efficiency.

But what are the total costs of a commercial electric vehicle compared to a diesel or petrol vehicle? How do the overall costs evolve over the years according to the holding period and annual mileage? How are greenhouse gas emissions reduced?

These and other questions are answered by this online calculator by the Öko-Institut. It analyzes the overall cost of commercial electric and plug-in hybrid vehicles - i.e costs for the purchase of vehicles and charging infrastructure, gasoline and electricity, workshop visits, tax, insurance, amortization and vehicle residual value.

Users can rely on plausible presets or adjust the individual variables manually to fit their own scenarios.

## Install

In order to set up the app locally, open the terminal.

Clone the repository with:

```
git clone git@github.com:oekoinstitut/kostenrechner.git
```

Go in the directory:

```
cd oeko-kostenrechner
```

You might need to install node and npm:

```
sudo apt-get install nodejs npm
```

Or on MacOS:

```
brew install npm
```

And some command line tools:

```
sudo npm -g install gulp bower
```

Install the dependencies

```
make install
```

Launch the app with

```
make run
```

## Install and run on Windows

Install a version of [node.js](https://nodejs.org/en/download/current/) above 5 using the Windows Installer. Install [Git](https://git-scm.com/download/win). Make sure that the SSH key associated with your Github account is on your computer ([here's how](https://help.github.com/articles/generating-an-ssh-key/)).

Open Git Bash and run the following commands.

Clone the repository with

```
git clone git@github.com:oekoinstitut/kostenrechner.git
```

Go in the directory

```
cd oeko-kostenrechner
```

Install the needed programs globally.

```
npm install -g bower
npm install -g gulp
```

Install the dependancies.

```
npm install
bower install
```

If needed, manually install node-sass

```
npm install node-sass@2.0.1
```

Test that it works by running the app on your computer. Internet Explorer will open.

```
gulp vehicle
```

```
gulp serve
```

Build current version:
```
gulp build
```

## Change the variables in the processor

Variables are in the presets.js file. Open it with

```
gedit processor/presets.js
```

make the changes needed and save the file.

Update the app with

```
gulp vehicle
```

It's recommended to push your changes to the git repository by doing

```
git add processor/presets.js
```

```
git commit -m "changed preset variables"
```

```
git push origin master
```

## Change the variables in the interface

Variables for the interface are in the following Google Spreadsheet: [https://docs.google.com/spreadsheets/d...](https://docs.google.com/spreadsheets/d/1-BxTbzc5z-04-0-3Q4KJTJtLKmmjAOE5s8X8bzEdv5Q/edit#gid=0)

Once the changes in the spreadsheet are made, update the app with

```
gulp gss
```

## Change the static texts

The texts are written in Markdown format and can be changed manually in the `src/assets/markdowns` folders.

## Publish the changes

Once everything runs well locally, publish the changes with

```
make deploy
```

And make sure to commit the changes to Github as well:

```
git add .
git commit -m "description of the changes"
git push origin master
```

## License

The code is property of Öko Institut e.V. and under an LGPL v3 license.
