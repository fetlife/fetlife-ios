# FetLife for iOS

Welcome to FetLife's open-source iOS app!

### Current Features

- View a list of your conversations
- Read and respond to conversations
- Notifications of new messages*
- Display a profile summary of the other user
- Safe For Work (SFW) mode blurs all pictures until double-tapped (enable or disable in settings)


### Requirements to run the app on your iPhone

- iPhone running iOS 9.0 or higher
- Mac running OS X 10.11 or later


### Screenshots of the App

![Screenshots of iOS App from a iPhone 6](https://cloud.githubusercontent.com/assets/22100/14684831/a0d2c0c4-06e6-11e6-8d9a-177caf8cb410.png)


### Installing the App on your iPhone for the first time

These instructions are written assuming you know very little about computers and to help get the app on your iPhone as quickly as possible:

1. Install the latest version of [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12).
2. Open the `Terminal` application up on your Mac.
3. Enter the following commands into your terminal window one by one and wait for them to finish:
  - `sudo gem install cocoapods` you will be prompted for your computers password
  - `git clone git@github.com:fetlife/ios.git`
  - `cd ios`
  - `pod install`
  - `open FetLife.xcworkspace`
4. Installing the app on your phone:
  - Connect your iPhone to your computer.
  - Select your iPhone from the "[Scheme toolbar menu](https://developer.apple.com/library/ios/documentation/IDEs/Conceptual/AppDistributionGuide/Art/5_launchappondevice_2x.png)".
  - Click the "Run" button.
  - If an error occurs saying the Bundle Identifier is unavailable, change the Bundle Identifier to something unique in Xcode and try again please.
5. Follow the instructions in the pop up windows i.e.:
  - Click "Fix Issue".
  - Enter in the username and password for your iCloud account.
  - "Select a Development Team" i.e your own name.
  - *You will probably have to do that 7-8 times*
  - Unlock your phone so your Mac can install the app onto your phone.
6. Trust your own developer on your iDevice under "Settings -> General -> Profile -> (your apple ID)"
7. Do the [happy dance](https://www.youtube.com/watch?v=Ckt5JgshnaA)! :-)


### Kinksters Helping Kinksters

Want to install the app on your phone but are not technically savvy? Ask your local kinky geek! Technically savvy and want to give back to the community... bring your laptop with you the next time you attend an event and install / update the app for anyone who's interested in having it install on their iPhone. *#KinkstersHelpingKinksters*


### Got Bugs?

If you find a bug please start by reading through the our current list of [open issues](https://github.com/fetlife/ios/issues) and if you can't find anything about your bug please [submit a new bug](https://github.com/fetlife/ios/issues/new).


### Want to Contribute

Woot woot! Please checkout our [Contributing Guidelines](https://github.com/fetlife/fetlife-ios/blob/master/CONTRIBUTING.md) and go from there.

### Frequently Asked Questions

- **Is a Mac required to install the application?** Yes, a Mac computer with at least OS X 10.11 or later is required to run the app and install it on a device. You can, however, install a precompiled `.ipa` file using [iTunes](https://www.apple.com/itunes/download/) on a Windows or Linux computer. Links to these files can usually be found in the latest closed pull request. Alternatively, you can ask someone who has a Mac to archive the app by going to "Product -> Archive", then clicking "Distribute" or "Export" and selecting "Distribute for Development". 
- **Why aren't I getting notifications when the app is closed?** Because this app isn't installed from the App Store, it is not currently possible to send true push (server-initiated) notifications. Instead, the app periodically checks with the FetLife server for any new messages using a method called "background fetching". (When the app is open, it checks for new messages approximately every 10 seconds.) However, the frequency of these requests cannot be directly controlled by the app and is instead managed by iOS. _In general_, the more frequently you get new messages the more often the app will check for new messages. In practice, however, the delay between a message being sent and receiving a notification can be up to 30 minutes or more.


### License

FetLife for iOS is released under the [MIT License](http://www.opensource.org/licenses/MIT).
