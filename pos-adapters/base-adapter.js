/**
 * Base POS Adapter
 * All POS connectors inherit from this class and implement these methods
 */
class POSAdapter {
  constructor(config = {}) {
    this.config = config;
    this.name = 'Base Adapter';
    this.type = 'unknown';
  }

  /**
   * Connect to the POS system
   * Validates credentials, stores auth tokens, etc.
   */
  async connect() {
    throw new Error('connect() must be implemented by subclass');
  }

  /**
   * Check if currently connected
   */
  async isConnected() {
    throw new Error('isConnected() must be implemented by subclass');
  }

  /**
   * Disconnect from POS
   */
  async disconnect() {
    throw new Error('disconnect() must be implemented by subclass');
  }

  /**
   * Get all staff/employees from POS
   * Must return standardized format:
   * [{id, name, role, wage, hireDate, phone}, ...]
   */
  async getStaff() {
    throw new Error('getStaff() must be implemented by subclass');
  }

  /**
   * Get all shifts from POS
   * Must return standardized format:
   * [{id, staffId, date, start, end}, ...]
   */
  async getShifts() {
    throw new Error('getShifts() must be implemented by subclass');
  }

  /**
   * Get sales data from POS
   * Must return standardized format:
   * [{id, date, dinein, takeout, delivery, catering}, ...]
   */
  async getSales(fromDate, toDate) {
    throw new Error('getSales() must be implemented by subclass');
  }

  /**
   * Transform POS data to standard format
   */
  transformStaff(posStaff) {
    return posStaff;
  }

  transformShifts(posShifts) {
    return posShifts;
  }

  transformSales(posSales) {
    return posSales;
  }

  /**
   * Save connection config to localStorage
   */
  saveConfig() {
    const posConfig = {
      type: this.type,
      connectedAt: new Date().toISOString(),
      config: this.config,
    };
    localStorage.setItem('pos-config', JSON.stringify(posConfig));
  }

  /**
   * Get saved config from localStorage
   */
  static loadConfig() {
    const saved = localStorage.getItem('pos-config');
    return saved ? JSON.parse(saved) : null;
  }

  /**
   * Clear POS connection
   */
  static clearConfig() {
    localStorage.removeItem('pos-config');
  }
}
