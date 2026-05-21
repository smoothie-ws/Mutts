package mutts.ui;

import s.ui.layouts.ColumnLayout;

abstract class MenuContent extends ColumnLayout {
	public final title:String;

	public function new(title:String) {
		super();
		this.title = title;
	}
}
