# Widget Extension Setup Guide

To enable the home screen widget for your life management app, follow these steps:

## 1. Add Widget Extension Target

1. In Xcode, go to **File > New > Target**
2. Select **Widget Extension**
3. Name it `knowbestWidget`
4. Make sure "Include Configuration Intent" is **unchecked** (we're using a static widget)
5. Click **Finish** and **Activate** the scheme when prompted

## 2. Configure App Groups

Both the main app and widget extension need to share data:

1. Select your **main app target** (`knowbest`)
2. Go to **Signing & Capabilities**
3. Click **+ Capability** and add **App Groups**
4. Add a new group: `group.Personal.knowbest`
5. Repeat steps 1-4 for the **widget extension target** (`knowbestWidget`)
6. Make sure both targets use the same App Group identifier

## 3. Add Files to Widget Target

1. Select `TodoItem.swift` in the Project Navigator
2. In the File Inspector (right panel), check the box next to `knowbestWidget` under **Target Membership**
3. Repeat for `TodoStore.swift` (the widget needs access to read todos)

## 4. Update Widget Files

The widget files are already created in the `knowbestWidget` folder. Make sure they're added to the widget extension target.

## 5. Build and Run

1. Build the project (⌘B)
2. Run the app on a device or simulator
3. Long press on the home screen to add the widget
4. Search for "knowbest" and add the "Todo Reminders" widget

## Notes

- The widget will automatically update every hour
- It shows up to 5 upcoming todos
- You can add widgets in small, medium, or large sizes
- The widget reads from the same data store as the app using App Groups
