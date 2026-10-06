/**
 * POS Adapter Manager
 * Handles instantiation and management of all POS adapters
 */

class POSAdapterManager {
  constructor() {
    this.currentAdapter = null;
    this.adapters = {
      csv: () => new CSVAdapter(),
      cluster: () => new ClusterAdapter(),
    };
  }

  /**
   * Get list of available adapters
   */
  getAvailableAdapters() {
    return [
      {
        type: 'csv',
        name: 'CSV Import',
        description: 'Upload data from any POS as CSV files',
        icon: 'upload',
        setup: 'Upload your employee list and sales data',
      },
      {
        type: 'cluster',
        name: 'Cluster POS',
        description: 'Direct connection to Cluster (Montreal-based)',
        icon: 'link',
        setup: 'Connect with your Cluster API key',
      },
      // Add more adapters here as they're built
      // {
      //   type: 'toast',
      //   name: 'Toast POS',
      //   description: 'Direct connection to Toast',
      //   icon: 'link',
      //   setup: 'Login with your Toast account',
      // },
      // {
      //   type: 'square',
      //   name: 'Square',
      //   description: 'Direct connection to Square',
      //   icon: 'link',
      //   setup: 'Login with your Square account',
      // },
    ];
  }

  /**
   * Get instance of specific adapter
   */
  getAdapter(type) {
    if (!this.adapters[type]) {
      throw new Error(`Unknown adapter type: ${type}`);
    }
    return this.adapters[type]();
  }

  /**
   * Set current active adapter
   */
  setCurrentAdapter(type) {
    this.currentAdapter = this.getAdapter(type);
    return this.currentAdapter;
  }

  /**
   * Get current adapter
   */
  getCurrentAdapter() {
    if (!this.currentAdapter) {
      // Try to restore from localStorage
      const config = POSAdapter.loadConfig();
      if (config && config.type) {
        this.currentAdapter = this.getAdapter(config.type);
      }
    }
    return this.currentAdapter;
  }

  /**
   * Check if any adapter is connected
   */
  async isConnected() {
    const adapter = this.getCurrentAdapter();
    if (!adapter) return false;
    return await adapter.isConnected();
  }

  /**
   * Load data from current adapter into database
   */
  async syncData() {
    const adapter = this.getCurrentAdapter();
    if (!adapter) {
      throw new Error('No POS adapter connected');
    }

    try {
      console.log('Syncing data from ' + adapter.name + '...');

      // Fetch data from adapter
      const staff = await adapter.getStaff();
      const shifts = await adapter.getShifts();
      const sales = await adapter.getSales(
        addDaysISO(todayISO(), -30),
        todayISO()
      );

      // Update database
      if (staff.length > 0) {
        DB.staff = staff;
      }
      if (shifts.length > 0) {
        DB.shifts = shifts;
      }
      if (sales.length > 0) {
        DB.sales = sales;
      }

      // Save to localStorage
      saveDB();

      console.log(
        `Synced: ${staff.length} staff, ${shifts.length} shifts, ${sales.length} sales`
      );
      return { staff: staff.length, shifts: shifts.length, sales: sales.length };
    } catch (err) {
      console.error('Sync failed:', err);
      throw err;
    }
  }

  /**
   * Disconnect current adapter
   */
  async disconnect() {
    if (this.currentAdapter) {
      await this.currentAdapter.disconnect();
      this.currentAdapter = null;
    }
  }
}

// Global instance
const POSManager = new POSAdapterManager();

// Export
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { POSAdapterManager, POSManager };
}
