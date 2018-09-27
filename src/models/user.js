import bookshelf from '../db';

const TABLE_NAME = 'ct_user_master';

/**
 * User model.
 */
class User extends bookshelf.Model {
  get tableName() {
    return TABLE_NAME;
  }

  get hasTimestamps() {
    return true;
  }
}

export default User;
