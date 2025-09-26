import { LightningElement, api } from 'lwc';

export default class QuoteDisplay extends LightningElement {
    @api title = 'Default Title'; // Title to display, with default value

    get hasTitle() {
        return this.title && this.title.trim().length > 0;
    }
}