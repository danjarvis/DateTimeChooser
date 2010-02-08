package ctz.flex.components
{
	/**
	 * Flex doesn't have a Date / Time Chooser... this is an implementation of one.
	 *
	 * Version 1.0.0
	 *
	 * Copyright (C) 2009 Daniel Jarvis
	 *
	 * This program is free software; you can redistribute it and/or
	 * modify it under the terms of the GNU General Public License as
	 * published by the Free Software Foundation; either version 2 of the License,
	 * or (at your option) any later version.
	 *
	 * This program is distributed in the hope that it will be useful,
	 * but WITHOUT ANY WARRANTY; without even the implied warranty of
	 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
	 *
	 * See the GNU General Public License for more details.
	 */
	import mx.containers.Box;
	import mx.containers.BoxDirection;
	import mx.controls.ComboBox;
	import mx.controls.DateField;
	import mx.controls.Label;
	import mx.controls.NumericStepper;
	import mx.events.CalendarLayoutChangeEvent;
	import mx.events.FlexEvent;
	import mx.events.ListEvent;
	import mx.events.NumericStepperEvent;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;

	[Event(name='DateTimeChanged')]
	public class DateTimeField extends Box
	{
		private var _selectedDateTime:Date;
		private var _oldDateTime:Date;
		private var _creationComplete:Boolean = false;
		private var _childrenEnabled:Number = -1;
		private var _separatorLabel:String;

		[Inspectable(category="Other", type="Boolean", enumeration="true,false")]
		private var _is24Hour:Boolean = false;

		[Inspectable(category="Other", type="Boolean", enumeration="true,false")]
		private var _showTime:Boolean = false;

		[Inspectable(category="Other", type="Boolean", enumeration="true,false")]
		private var _showDate:Boolean = false;

		[Inspectable(category="Other", type="Boolean", enumeration="true,false")]
		private var _showLabels:Boolean = false;

		[Inspectable(category="Other", type="Boolean", enumeration="true,false")]
		private var _showSeparatorLabel:Boolean = false;

		private var _meridianArray:Array = [{string:"AM", value:0}, {string:"PM", value:1}];

		private var bShowTimeChanged:Boolean = false;
		private var bShowDateChanged:Boolean = false;
		private var bIs24HourChanged:Boolean = false;
		private var bShowLabelsChanged:Boolean = false;
		private var bShowSeparatorLabelChanged:Boolean = false;

		private var dtDateField:DateField = null;
		private var nsHours:NumericStepper = null;
		private var nsMinutes:NumericStepper = null;
		private var cmbMeridian:ComboBox = null;
		private var lblHours:Label = null;
		private var lblColon:Label = null;
		private var lblMinutes:Label = null;
		private var lblSeparator:Label = null;

		public function DateTimeField()
		{
			super();
			this.addEventListener(FlexEvent.CREATION_COMPLETE, handleCreationComplete);
		}

	/** ----------------------------------------------------------------------
	 * 					Create & Add Children
	 * --------------------------------------------------------------------- */
		private function createDateField():void
		{
			if (this.getChildByName('dispDateField') == null) {
				this.dtDateField = new DateField();
				this.dtDateField.name = 'dispDateField';
				this.dtDateField.useHandCursor = true;
				this.dtDateField.buttonMode = true;
				this.dtDateField.width = 120;
				this.dtDateField.height = 22;
				this.dtDateField.setStyle('fontSize', 12);
				this.dtDateField.yearNavigationEnabled = true;
				this.dtDateField.showToday = true;
				this.dtDateField.addEventListener(CalendarLayoutChangeEvent.CHANGE, dtDateFieldChanged);
				this.addChild(this.dtDateField);
			}
		}

		private function createHours():void
		{
			if (this.getChildByName('dispHours') == null) {
				this.nsHours = new NumericStepper();
				this.nsHours.name = 'dispHours';
				this.nsHours.useHandCursor = true;
				this.nsHours.buttonMode = true;
				this.nsHours.maximum = (this._is24Hour) ? 25 : 13;
				this.nsHours.minimum = (this._is24Hour) ? -1 : 0;
				this.nsHours.value = (this._is24Hour) ? 0 : 12;
				this.nsHours.width = 60;
				this.nsHours.height = 22;
				this.nsHours.setStyle('fontSize', 12);
				this.nsHours.setStyle('cornerRadius', 5);
				this.nsHours.addEventListener(NumericStepperEvent.CHANGE, nsHoursChanged);
				this.addChild(this.nsHours);
			}

		}

		private function createMinutes():void
		{
			if (this.getChildByName('dispMinutes') == null) {
				this.nsMinutes = new NumericStepper();
				this.nsMinutes.name = 'dispMinutes';
				this.nsMinutes.useHandCursor = true;
				this.nsMinutes.buttonMode = true;
				this.nsMinutes.maximum = 60
				this.nsMinutes.minimum = -1;
				this.nsMinutes.width = 60;
				this.nsMinutes.height = 22;
				this.nsMinutes.setStyle('fontSize', 12);
				this.nsMinutes.setStyle('cornerRadius', 5);
				this.nsMinutes.addEventListener(NumericStepperEvent.CHANGE, nsMinutesChanged);
				this.addChild(this.nsMinutes);
			}
		}

		private function createMeridian():void
		{
			if (!this._showTime)
				return;

			if (this.getChildByName('dispMeridian') == null) {
				this.cmbMeridian = new ComboBox();
				this.cmbMeridian.name = 'dispMeridian';
				this.cmbMeridian.dataProvider = this._meridianArray;
				this.cmbMeridian.labelField = 'string';
				this.cmbMeridian.useHandCursor = true;
				this.cmbMeridian.buttonMode = true;
				this.cmbMeridian.width = 60;
				this.cmbMeridian.height = 22;
				this.cmbMeridian.setStyle('fontSize', 12);
				this.cmbMeridian.setStyle('fontWeight', 'normal');
				this.cmbMeridian.setStyle('cornerRadius', 5);
				this.cmbMeridian.addEventListener(ListEvent.CHANGE, cmbMeridianChanged);
				this.addChild(this.cmbMeridian);

				this.nsHours.maximum = 13;
				this.nsHours.minimum = 0;
				this.doWrapAround();
			}
		}

		private function createTimeLabels():void
		{
			// Only add the time labels if we are showing the time fields.
			if (this._showTime) {
				if (this.getChildByName('hoursLabel') == null) {
					this.lblHours = new Label();
					this.lblHours.name = 'hoursLabel';
					this.lblHours.text = 'Hr';
					this.lblHours.setStyle('fontSize', 12);
					this.lblHours.setStyle('fontWeight', 'normal');
					this.addChildAt(this.lblHours, (this.getChildIndex(this.getChildByName('dispHours'))));
				}

				if (this.getChildByName('colonLabel') == null) {
					this.lblColon = new Label();
					this.lblColon.name = 'colonLabel';
					this.lblColon.text = ':';
					this.lblColon.setStyle('fontSize', 12);
					this.lblColon.setStyle('fontWeight', 'normal');
					this.addChildAt(this.lblColon, (this.getChildIndex(this.getChildByName('dispMinutes'))));
				}
				if (this.getChildByName('minutesLabel') == null) {
					this.lblMinutes = new Label();
					this.lblMinutes.name = 'minutesLabel';
					this.lblMinutes.text = 'Min';
					this.lblMinutes.setStyle('fontSize', 12);
					this.lblMinutes.setStyle('fontWeight', 'normal');
					this.addChildAt(this.lblMinutes, (this.getChildIndex(this.getChildByName('dispMinutes'))));
				}
			}
		}

		private function addTimeFields():void
		{
			this.createHours();
			this.createMinutes();
			if (!this._is24Hour)
				this.createMeridian();
		}

		private function createSeparatorLabel():void
		{
			if (this.getChildByName('separatorLabel') == null) {
				this.lblSeparator = new Label();
				this.lblSeparator.name = 'separatorLabel';
				this.lblSeparator.text = this._separatorLabel;
				this.lblSeparator.setStyle('fontSize', 12);
				this.lblSeparator.setStyle('fontWeight', 'normal');
				this.lblSeparator.width = 125;

				this.addChildAt(this.lblSeparator, 1);
			}
		}

	/** ----------------------------------------------------------------------
	 * 					Remove Children
	 * --------------------------------------------------------------------- */

		private function removeTimeFields():void
		{
			this.removeHours();
			this.removeMinutes();
			this.removeMeridian();
			this.removeTimeLabels();
		}

		private function removeHours():void
		{
			if (this.getChildByName('dispHours') != null)
				this.removeChild(this.getChildByName('dispHours'));
		}

		private function removeMinutes():void
		{
			if (this.getChildByName('dispMinutes') != null)
				this.removeChild(this.getChildByName('dispMinutes'));
		}

		private function removeMeridian():void
		{
			if (this.getChildByName('dispMeridian') != null)
				this.removeChild(this.getChildByName('dispMeridian'));

			if (this._showTime) {
				this.nsHours.maximum = 25;
				this.nsHours.minimum = -1;
				this.doWrapAround();
			}
		}

		private function removeDateField():void
		{
			if (this.getChildByName('dispDateField') != null)
				this.removeChild(this.getChildByName('dispDateField'));
		}

		private function removeTimeLabels():void
		{
			if (this.getChildByName('hoursLabel') != null)
				this.removeChild(this.getChildByName('hoursLabel'));

			if (this.getChildByName('colonLabel') != null)
				this.removeChild(this.getChildByName('colonLabel'));

			if (this.getChildByName('minutesLabel') != null)
				this.removeChild(this.getChildByName('minutesLabel'));
		}

		private function removeSeparatorLabel():void
		{
			if (this.getChildByName('separatorLabel') != null)
				this.removeChild(this.getChildByName('separatorLabel'));
		}

	/** ----------------------------------------------------------------------
	 * 					Overrides
	 * --------------------------------------------------------------------- */

		override protected function createChildren():void
		{
			super.createChildren();
			this.createDateField();
			if (this._showTime) {
				this.addTimeFields();
			}
			this.dtDateField.visible = this._showDate;
			this.dtDateField.includeInLayout = this._showDate;
		}

		override protected function commitProperties():void
		{
			super.commitProperties();

			if (this.bShowDateChanged) {
				this.bShowDateChanged = false;
				this.dtDateField.visible = this._showDate;
				this.dtDateField.includeInLayout = this.showDate;
			}

			if (this.bShowTimeChanged) {
				this.bShowTimeChanged = false;
				this._showTime ? this.addTimeFields() : this.removeTimeFields();
				this.updateSelectedDate();
			}

			if (this.bIs24HourChanged) {
				this.bIs24HourChanged = false;
				this._is24Hour ? this.removeMeridian() : this.createMeridian();
				this.updateSelectedDate();
			}

			if (this.bShowLabelsChanged) {
				this.bShowLabelsChanged = false;
				this._showLabels ? this.createTimeLabels() : this.removeTimeLabels();
			}

			if (this.bShowSeparatorLabelChanged) {
				this.bShowSeparatorLabelChanged = false;
				this._showSeparatorLabel ? this.createSeparatorLabel() : this.removeSeparatorLabel();
			}
		}

		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);

			// Comment out the 3 lines below to allow direction
			if (this.direction == null || this.direction == '' || this.direction == BoxDirection.VERTICAL) {
				this.direction = BoxDirection.HORIZONTAL;
			}
		}

		override public function toString():String
		{
			return this.dtDateField.toString()
		}

	/** ----------------------------------------------------------------------
	 * 					Event Listeners & Misc.
	 * --------------------------------------------------------------------- */

		private function handleCreationComplete(event:Event):void
		{
			this._creationComplete = true;
			this.setStyle('borderStyle','solid');;
			this.setStyle('borderThickness', 1);
			this.setStyle('cornerRadius', 5);

			// If _selectedDateTime was set before _creationComplete
			// we need to make sure to call setDateTimeControls() again.
			if (this._selectedDateTime != null)
				this.setDateTimeControls();

			// If _childrenEnabled was set before _creationComplete
			// we need to make sure to update it
			if (this._childrenEnabled != -1)
				this.childrenEnabled = this._childrenEnabled;
		}

		private function dtDateFieldChanged(event:Event):void
		{
			this.updateSelectedDate();
		}

		private function nsHoursChanged(event:Event):void
		{
			this.doWrapAround();
		}

		private function nsMinutesChanged(event:Event):void
		{
			this.doWrapAround();
		}

		private function cmbMeridianChanged(event:Event):void
		{
			this.updateSelectedDate();
		}

		/**
		 * A sad attempt at adding wrapping functionality
		 */
		private function doWrapAround():void
		{
			if (!this._showTime || !this._creationComplete)
				return;

			// Hours
			if (!this._is24Hour) {
				if (this.nsHours.value >= this.nsHours.maximum) {
					this.nsHours.value = this.nsHours.minimum + 1;
				} else if (this.nsHours.value <= this.nsHours.minimum) {
					this.nsHours.value = this.nsHours.maximum - 1;
				}
			} else {
				if (this.nsMinutes.value > 0 && this.nsHours.value >= this.nsHours.maximum - 1) {
					this.nsHours.value = this.nsHours.minimum + 1;
				} else if (this.nsMinutes.value == 0 && this.nsHours.value >= this.nsHours.maximum) {
					this.nsHours.value = this.nsHours.minimum + 1;
				} else if (this.nsHours.value <= this.nsHours.minimum) {
					if (this.nsMinutes.value > 0) {
						this.nsHours.value = this.nsHours.maximum - 2;
					} else {
						this.nsHours.value = this.nsHours.maximum - 1;
					}
				}
			}

			// Minutes
			if (this.nsMinutes.value >= this.nsMinutes.maximum) {
				this.nsMinutes.value = this.nsMinutes.minimum + 1;
			} else if (this.nsMinutes.value <= this.nsMinutes.minimum) {
				this.nsMinutes.value = this.nsMinutes.maximum - 1;
			}

			this.updateSelectedDate();
		}

		/**
		 * Update _selectedDateTime property when any of the Date Controls change
		 */
		private function updateSelectedDate():void
		{
			if (!this._creationComplete)
				return;

			if (this.dtDateField.selectedDate == null)
				return;

			this._selectedDateTime = this.dtDateField.selectedDate;
			this._selectedDateTime.fullYear = (this.dtDateField.selectedDate != null) ? this.dtDateField.selectedDate.fullYear : null;
			this._selectedDateTime.month = (this.dtDateField.selectedDate != null) ? this.dtDateField.selectedDate.month : null;
			this._selectedDateTime.date = (this.dtDateField.selectedDate != null) ? this.dtDateField.selectedDate.date : null;

			// Hours requires tiny bit more logic
			if (this._showTime) {
				if (!this._is24Hour) {
					if (this.cmbMeridian.selectedIndex == 0) {		// AM
						this._selectedDateTime.hours = (this.nsHours.value == 12) ? 0 : this.nsHours.value;
					} else {											// PM
						this._selectedDateTime.hours = (this.nsHours.value != 12) ? (this.nsHours.value + 12) : 12;
					}
				} else {
					this._selectedDateTime.hours = this.nsHours.value;
				}
			} else {
				this._selectedDateTime.hours = 0;
			}
			this._selectedDateTime.minutes = this.showTime ? this.nsMinutes.value : 0;
			this._selectedDateTime.seconds = 0;
			this._selectedDateTime.milliseconds = 0;

			this.dispatchEvent(new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE, false, false, PropertyChangeEventKind.UPDATE, 'selectedDateTime', null, this));
			this.dispatchEvent(new Event('DateTimeChanged'));
		}

		/**
		 * When the _selecteDateTime is set update the value of the Date Controls
		 */
		private function setDateTimeControls():void
		{
			if (!this._creationComplete)
				return;

			this.dtDateField.selectedDate = this._selectedDateTime;
			if (this._showTime) {
				this.nsMinutes.value = this._selectedDateTime.getMinutes();
				if (this._is24Hour) {
					this.nsHours.value = this._selectedDateTime.getHours();
				} else {
					var hrs:Number = this._selectedDateTime.getHours();
					this.nsHours.value = (hrs <= 12 ) ? (hrs == 0 ? 12 : hrs) : hrs - 12;
					this.cmbMeridian.selectedIndex = (hrs >= 12) ? 1 : 0;
				}
			}
		}

		public function clear():void
		{
			this._selectedDateTime = null;
			this.dtDateField.selectedDate = null;
			this.dtDateField.text = '';
			if (this._showTime) {
				this.nsHours.value = 1;
				this.nsMinutes.value = 0;
				if (!this._is24Hour)
					this.cmbMeridian.selectedIndex = 0;
			}
		}

		/**
		 * Disable / Enable all children.
		 * Note: Overriding the parent's setter for 'enabled' doesn't quite work as I need it to.
		 */
		public function set childrenEnabled(value:Boolean):void
		{
			this._childrenEnabled = Number(value);

			if (!this._creationComplete)
				return;

			this.dtDateField.enabled = value;
			if (this._showTime) {
				this.nsHours.enabled = value;
				this.nsMinutes.enabled = value;

				if (!this._is24Hour)
					this.cmbMeridian.enabled = value;

				if (this._showLabels) {
					this.lblHours.enabled = value;
					this.lblMinutes.enabled = value;
					this.lblColon.enabled = value;
				}
			}

			this.invalidateDisplayList();
		}

	/** ----------------------------------------------------------------------
	 * 					Getters / Setters
	 * --------------------------------------------------------------------- */

		public function get dateField():DateField { return this.dtDateField; }
		public function get hoursField():NumericStepper { return this.nsHours; }
		public function get minutesField():NumericStepper { return this.nsMinutes; }
		public function get meridianField():ComboBox { return this.cmbMeridian; }
		public function get hoursLabel():Label { return this.lblHours; }
		public function get colonLabel():Label { return this.lblColon; }
		public function get minutesLabel():Label { return this.lblMinutes; }


		public function get creationComplete():Boolean { return this._creationComplete; }

		[Bindable]
		public function get is24Hour():Boolean { return this._is24Hour; }
		public function set is24Hour(value:Boolean):void
		{
			this.bIs24HourChanged = true;
			this._is24Hour = value;
			this.invalidateProperties();
		}

		[Bindable]
		public function get selectedDateTime():Date { return this._selectedDateTime; }
		public function set selectedDateTime(value:Date):void
		{
			this._selectedDateTime = value;
			this.setDateTimeControls();
		}

		[Bindable]
		public function get showTime():Boolean { return this._showTime; }
		public function set showTime(value:Boolean):void
		{
			this._showTime = value;
			this.bShowTimeChanged = true;
			this.invalidateProperties();
		}

		[Bindable]
		public function get showDate():Boolean { return this._showDate; }
		public function set showDate(value:Boolean):void
		{
			this._showDate = value;
			this.bShowDateChanged = true;
			this.invalidateProperties();
		}

		[Bindable]
		public function get showLabels():Boolean { return this._showLabels; }
		public function set showLabels(value:Boolean):void
		{
			this._showLabels = value;
			this.bShowLabelsChanged = true;
			this.invalidateProperties();
		}

		[Bindable]
		public function get separatorLabel():String { return this._separatorLabel; }
		public function set separatorLabel(value:String):void
		{
			this._separatorLabel = value;
			this.bShowSeparatorLabelChanged = true;
			this.invalidateProperties();
		}

		[Bindable]
		public function get showSeparatorLabel():Boolean { return this._showSeparatorLabel; }
		public function set showSeparatorLabel(value:Boolean):void
		{
			this._showSeparatorLabel = value;
			this.bShowSeparatorLabelChanged = true;
			this.invalidateProperties();
		}

		/**
		 * Return only the time portion as hh:mm:ss
		 */
		public function getTime():String
		{
			if (!this._showTime)
				return "";
			return this.dtDateField.selectedDate.getHours() + ":" + this.dtDateField.selectedDate.getMinutes() + ":" + this.dtDateField.selectedDate.getSeconds();
		}
	}
}