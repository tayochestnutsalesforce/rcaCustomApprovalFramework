import { LightningElement, api, track } from 'lwc';
import getFlattenedLiveApprovalForQuote from '@salesforce/apex/ApprovalPreviewController.getFlattenedLiveApprovalForQuote';
import getApprovalAnswers from '@salesforce/apex/ApprovalPreviewController.getApprovalAnswers';
import APPROVAL_ICONS from '@salesforce/resourceUrl/ApprovalPreviewIcons';

export default class ApprovalPreviewMosaic extends LightningElement {
    @api recordId; // assume Quote Id passed in from record page or Flow
    /**
     * JSON or semicolon-delimited mapping of Status -> color value.
     * Examples:
     *   JSON: {"Approved":"#2ecc71","N/A":"#999999"}
     *   KV: Approved=#2ecc71;N/A=#999999
     */
    @api statusColorMap = '';
    // Individual per-status color overrides (editable in App Builder / Flow screen)
    @api approvedColor = '';
    @api rejectedColor = '';
    @api pendingColor = '';
    @api naColor = '';
    @track items = [];
    @track loading = true;
    error;

    connectedCallback() {
        this.loadData();
    }

    renderedCallback() {
        // Apply status colors to DOM elements after render
        this._applyStatusColors();
        // Setup tooltip hover handlers
        this._setupTooltipHandlers();
    }

    _applyStatusColors() {
        // cards with data-status-color
        const cards = this.template.querySelectorAll('[data-status-color]');
        if (!cards) return;
        cards.forEach(el => {
            const color = el.getAttribute('data-status-color');
            if (color) {
                // apply a left border for the entire card
                el.style.borderLeft = `6px solid ${color}`;
            }
        });

        // small indicator dots
        const dots = this.template.querySelectorAll('.statusIndicator[data-status-color]');
        dots.forEach(d => {
            const color = d.getAttribute('data-status-color');
            if (color) d.style.backgroundColor = color;
        });
    }

    _setupTooltipHandlers() {
        const tooltipContainers = this.template.querySelectorAll('.tooltip-container');
        
        tooltipContainers.forEach(container => {
            const tooltip = container.querySelector('.tooltip');
            if (!tooltip) return;
            
            // Remove existing event listeners to prevent duplicates
            container.removeEventListener('mouseenter', this._showTooltip);
            container.removeEventListener('mouseleave', this._hideTooltip);
            
            // Add new event listeners
            container.addEventListener('mouseenter', (event) => {
                this._showTooltip(event, tooltip);
            });
            
            container.addEventListener('mouseleave', (event) => {
                this._hideTooltip(event, tooltip);
            });
        });
    }

    _showTooltip(event, tooltip) {
        // Add a small delay before showing tooltip
        setTimeout(() => {
            tooltip.classList.add('show');
        }, 300);
    }

    _hideTooltip(event, tooltip) {
        tooltip.classList.remove('show');
    }

    async loadData() {
        this.loading = true;
        this.error = undefined;
        try {
            const rows = await getFlattenedLiveApprovalForQuote({ quoteId: this.recordId });
            // Clone and enrich rows (avoid mutating framework proxy)
            const clones = (rows || []).map(r => {
                const row = Object.assign({}, r);
                row._key = (row.ApprovalRuleId ? row.ApprovalRuleId : row.Id) + '-' + (row.ApprovalRuleSlot ? row.ApprovalRuleSlot : '0');
                row._avatar = this._computeAvatar(row);
                row._statusColor = this._mapStatusColor(row.Status);
                return row;
            });

            // Fetch approval answers for each unique approval rule
            const uniqueRuleIds = [...new Set(clones.map(c => c.ApprovalRuleId).filter(id => id))];
            const answerPromises = uniqueRuleIds.map(ruleId => 
                getApprovalAnswers({ quoteId: this.recordId, approvalRuleId: ruleId })
            );
            
            const answersResults = await Promise.all(answerPromises);
            const answersMap = {};
            
            // Build a map of ruleId -> answers array
            uniqueRuleIds.forEach((ruleId, index) => {
                answersMap[ruleId] = answersResults[index] || [];
            });
            
            // Add approval answers to each clone
            clones.forEach(clone => {
                if (clone.ApprovalRuleId && answersMap[clone.ApprovalRuleId]) {
                    clone._approvalAnswers = answersMap[clone.ApprovalRuleId];
                } else {
                    clone._approvalAnswers = [];
                }
            });

            // Build a matrix where each row is a Level and each column is a Chain
            // 1) determine ordered list of chains
            const chainOrder = [];
            const seenChains = {};
            clones.forEach(c => {
                const name = c.Chain || 'Default';
                if (!seenChains[name]) {
                    seenChains[name] = true;
                    chainOrder.push({ name, key: `chain-${chainOrder.length}` });
                }
            });

            // 2) determine sorted unique levels
            const levelSet = new Set();
            clones.forEach(c => {
                const lvl = c.Level == null ? 0 : Number(c.Level);
                levelSet.add(lvl);
            });
            const levels = Array.from(levelSet).sort((a,b) => a - b);

            // 3) build rows: for each level, produce cells for each chain (allow multiple items per cell)
            const matrixRows = levels.map(lvl => {
                const cells = chainOrder.map(ch => {
                    // gather all matches for this chain+level so we can render stacked cards
                    const matches = clones.filter(r => {
                        const rLevel = r.Level == null ? 0 : Number(r.Level);
                        const rChain = r.Chain || 'Default';
                        return rLevel === lvl && rChain === ch.name;
                    });
                    if (matches && matches.length) {
                        // sort by slot/order so stacked items display in sequence
                        matches.sort((a,b) => (Number(a.ApprovalRuleSlot)||0) - (Number(b.ApprovalRuleSlot)||0));
                        const items = matches.map(found => ({
                            _key: found._key,
                            title: found.Title,
                            approverName: found.ApproverName,
                            avatar: found._avatar,
                            slot: found.ApprovalRuleSlot,
                            status: found.Status,
                            statusColor: found._statusColor,
                            approvalAnswers: found._approvalAnswers,
                            _raw: found
                        }));
                        return { chainKey: ch.key, chainName: ch.name, hasItem: true, items };
                    }
                    return { chainKey: ch.key, chainName: ch.name, hasItem: false, items: [] };
                });
                return { level: lvl, cells };
            });

            this.chainsList = chainOrder;
            this.uniqueLevels = levels;
            this.matrixRows = matrixRows;
        } catch (e) {
            this.error = e;
            this.items = [];
        } finally {
            this.loading = false;
        }
    }

    get avatarBase() {
        return APPROVAL_ICONS;
    }

    // helper to build avatar URL if AvatarUrl is a resource path
    avatarFor(item) {
        if (!item || !item.AvatarUrl) return `${this.avatarBase}/user.svg`;
        if (typeof item.AvatarUrl === 'string' && (item.AvatarUrl.indexOf('/resource/') === 0 || item.AvatarUrl.startsWith('http'))) return item.AvatarUrl;
        return `${this.avatarBase}/${item.AvatarUrl}`;
    }

    imgError(event) {
        // set fallback icon from static resource
        event.target.src = `${this.avatarBase}/user.svg`;
    }

    // private avatar computation used at data load time so template bindings are simple properties
    _computeAvatar(item) {
        if (!item || !item.AvatarUrl) return `${this.avatarBase}/user.svg`;
        if (typeof item.AvatarUrl === 'string' && (item.AvatarUrl.indexOf('/resource/') === 0 || item.AvatarUrl.startsWith('http'))) return item.AvatarUrl;
        return `${this.avatarBase}/${item.AvatarUrl}`;
    }

    // Parse statusColorMap (JSON or semicolon/kv string) to a lookup object
    _parseStatusColorMap() {
        if (!this.statusColorMap) return {};
        // try JSON first and normalize keys to lowercase
        try {
            const parsed = JSON.parse(this.statusColorMap);
            if (parsed && typeof parsed === 'object') {
                const normalized = {};
                Object.keys(parsed).forEach(k => {
                    if (k && parsed[k]) normalized[k.trim().toLowerCase()] = parsed[k];
                });
                return normalized;
            }
        } catch (e) {
            // fall through to KV parser
        }

        const map = {};
        // support formats like: Approved=#2ecc71;N/A=#999999
        const parts = this.statusColorMap.split(';');
        parts.forEach(p => {
            const kv = p.split('=');
            if (kv.length === 2) {
                const k = kv[0].trim();
                const v = kv[1].trim();
                if (k) map[k.toLowerCase()] = v;
            }
        });
        return map;
    }

    _mapStatusColor(status) {
        const s = (status || '').toString().trim();
        const key = s.toLowerCase();

        // Prefer explicit per-status @api properties when provided
        if (key === 'approve' && this.approvedColor) return this.approvedColor;
        if (key === 'reject' && this.rejectedColor) return this.rejectedColor;
        if (key === 'pending' && this.pendingColor) return this.pendingColor;
        if ((key === 'n/a' || key === 'na') && this.naColor) return this.naColor;

        // fallback to statusColorMap (keys normalized to lowercase)
        const map = this._parseStatusColorMap();
        const color = map[key] || map[s] || map[status];

        return color || this.naColor || '#cccccc';
    }
}
