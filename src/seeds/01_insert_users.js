/**
 * Seed users table.
 *
 * @param  {object} knex
 * @param  {object} Promise
 * @return {Promise}
 */
export function seed(knex, Promise) {
  // Deletes all existing entries
  return knex('users')
    .del()
    .then(() => {
      return Promise.all([
        // Inserts seed entries
        knex('users').insert([
          {
            name: 'Kundan Singh',
            updated_at: new Date()
          },
          {
            name: 'Sunil Kamble',
            updated_at: new Date()
          },
          {
            name: 'Bajrang Kadam',
            updated_at: new Date()
          },
          {
            name: 'Deven Patel',
            updated_at: new Date()
          },
          {
            name: 'Jainam Vora',
            updated_at: new Date()
          },
        ])
      ]);
    });
}
