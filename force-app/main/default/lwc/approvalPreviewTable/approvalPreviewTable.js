import { LightningElement, api, track } from 'lwc';
import getFlattenedLiveApprovalForQuote from '@salesforce/apex/ApprovalPreviewController.getFlattenedLiveApprovalForQuote';

export default class ApprovalPreviewTable extends LightningElement {
    @api flowData; // optional JSON string passed from Flow
    @api quoteId; // optional Quote Id to filter previews
    @api maxLevel = 5; // render placeholder levels up to this number
    @api dividerLevel = 2; // level at which to render the divider
    @track chains = {};
    @track chainsList = [];
    @track loading = false;
    @track error;
    // view state: 'grid' or 'table'
    @track view = 'grid';
    @track tableRows = [];
    // columns for lightning-datatable
    columns = [
        { label: 'Chain', fieldName: 'Chain', type: 'text' },
        { label: 'Level', fieldName: 'Level', type: 'number' },
        { label: 'Order', fieldName: 'Order', type: 'number' },
        { label: 'Approver', fieldName: 'ApproverName', type: 'text' },
        { label: 'Title', fieldName: 'Title', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Notes / URL', fieldName: 'URLLabel', type: 'text' },
    ];

    connectedCallback() {
        this.loadData();
    }

    async loadData() {
        this.loading = true;
        this.error = undefined;
        try {
            let raw;
            if (this.flowData) {
                try {
                    raw = JSON.parse(this.flowData);
                } catch (e) {
                    // fallback to Apex on parse error
                    raw = null;
                }
            }
            if (!raw) {
                if (this.quoteId) {
                    raw = await getFlattenedLiveApprovalForQuote({ quoteId: this.quoteId });
                } else {
                    // If no quoteId provided, we can't load data with the current controller
                    this.error = 'Quote ID is required to load approval preview data';
                    return;
                }
            }

            this.processRaw(raw || []);
        } catch (e) {
            this.error = e.body && e.body.message ? e.body.message : String(e);
        } finally {
            this.loading = false;
        }
    }

    processRaw(raw) {
        // Group by Chain, sort by Order then Level
        const map = new Map();
        raw.forEach(item => {
            const chain = item.Chain || 'Default';
            if (!map.has(chain)) map.set(chain, []);
            map.get(chain).push(item);
        });

        const chainsArr = [];
        for (const [key, items] of map.entries()) {
            items.sort((a,b)=> (a.Order||0) - (b.Order||0) || (a.Level||0) - (b.Level||0));
            // Group items by Level into levelBlocks
            const levelMap = new Map();
            items.forEach(it => {
                const lvl = it.Level || 0;
                if (!levelMap.has(lvl)) levelMap.set(lvl, []);
                levelMap.get(lvl).push(it);
            });
            const levels = [];
            // ensure levels 1..maxLevel exist as blocks (even if empty)
            for (let lvl = 1; lvl <= (this.maxLevel || 5); lvl++) {
                const itemsAtLevel = levelMap.has(lvl) ? levelMap.get(lvl) : [];
                const blockRows = itemsAtLevel.map((it, idx) => ({ key: it.Id || (lvl+'-'+idx), ...it }));
                levels.push({ level: lvl, rows: blockRows, rowsCount: blockRows.length, divider: lvl === (this.dividerLevel || 2) });
            }
            chainsArr.push({ key, levels });
        }

        // Sort columns by the minimum Order value to make chains stable.
        // Each chain has a .levels array; find the first non-empty level and use its first row's Order.
        const getMinOrder = (chain) => {
            if (!chain || !Array.isArray(chain.levels)) return 0;
            for (const lvl of chain.levels) {
                if (lvl && Array.isArray(lvl.rows) && lvl.rows.length) return lvl.rows[0].Order || 0;
            }
            return 0;
        };
        chainsArr.sort((a,b)=> getMinOrder(a) - getMinOrder(b));

        // Pad levels so each chain has the same number of row slots per level.
        const maxPerLevel = new Map();
        for (const chain of chainsArr) {
            for (const lvl of chain.levels) {
                const curr = maxPerLevel.get(lvl.level) || 0;
                maxPerLevel.set(lvl.level, Math.max(curr, lvl.rowsCount || 0));
            }
        }

        // For each chain/level, if rows.length < max for that level, push placeholder slots
        for (const chain of chainsArr) {
            for (const lvl of chain.levels) {
                const maxSlots = maxPerLevel.get(lvl.level) || 0;
                lvl.rows = Array.isArray(lvl.rows) ? lvl.rows : [];
                const missing = maxSlots - (lvl.rows.length || 0);
                for (let i = 0; i < missing; i++) {
                    lvl.rows.push({ key: `placeholder-${lvl.level}-${i}`, _placeholder: true });
                }
                // update rowsCount to reflect total slots
                lvl.rowsCount = lvl.rows.length;
            }
        }

        this.chainsList = chainsArr;

        // Build flat tableRows from raw items (or from chainsArr) preserving key fields
        const rows = [];
        chainsArr.forEach(chain => {
            chain.levels.forEach(levelBlock => {
                levelBlock.rows.forEach(row => {
                    // Ensure consistent field names expected by table template
                    rows.push({
                        key: row.key || `${chain.key}-${levelBlock.level}-${rows.length}`,
                        Chain: chain.key,
                        Level: levelBlock.level,
                        Order: row.Order || '',
                        ApproverName: row.ApproverName || row.Approver || '',
                        Title: row.Title || row.Approver_Title || '',
                        Status: row.Status || '',
                        Notes: row.Notes || '',
                        URL: row.URL || '',
                        LiveApprovalId: row.LiveApprovalId || '',
                        ApprovalRuleId: row.ApprovalRuleId || '',
                        _placeholder: !!row._placeholder,
                        // add a simple class name to bind in template (avoid ternary in template)
                        _rowClass: row._placeholder ? 'placeholder-row' : ''
                    });
                });
            });
        });
        // add display label for notes/url column
        rows.forEach(r => {
            r.URLLabel = r.URL ? 'Link' : (r.Notes || '');
        });
        this.tableRows = rows;
    }

    get isGrid() { return this.view === 'grid'; }
    get isTable() { return this.view === 'table'; }

    handleToggle(evt) {
        const view = evt.currentTarget && evt.currentTarget.dataset && evt.currentTarget.dataset.view;
        if (view) this.view = view;
        // update aria-pressed on buttons for basic accessibility
        this.template.querySelectorAll('.toggle-button').forEach(btn => btn.setAttribute('aria-pressed', btn.dataset.view === this.view));
    }
}
