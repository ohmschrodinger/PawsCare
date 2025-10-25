import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import cors from 'cors';

const corsHandler = cors({ origin: true });

// ============================================================================
// Pet of the Day - Automated Daily Selection
// ============================================================================

/**
 * Scheduled function that runs daily at midnight UTC to select a random
 * available pet as the "Pet of the Day"
 * 
 * Database Requirements:
 * - status: 'Available for Adoption' (exact match required)
 * - approvalStatus: 'approved' (exact match required)
 * - isActive: true (optional filter for extra safety)
 */
export const updatePetOfTheDay = functions.pubsub
  .schedule('0 0 * * *') // Run at midnight UTC every day
  .timeZone('UTC')
  .onRun(async (context) => {
    try {
      console.log('Starting Pet of the Day update...');

      // Query for available pets with correct status value
      const availablePetsSnapshot = await admin.firestore()
        .collection('animals')
        .where('status', '==', 'Available for Adoption')
        .where('approvalStatus', '==', 'approved')
        .where('isActive', '==', true)
        .get();

      console.log(`Found ${availablePetsSnapshot.docs.length} available pets`);

      if (availablePetsSnapshot.empty) {
        console.log('No available pets found for Pet of the Day');
        // Set a default/placeholder
        await admin.firestore().collection('app_config').doc('pet_of_the_day').set({
          selectedAt: admin.firestore.FieldValue.serverTimestamp(),
          hasPet: false,
          message: 'No pets available at the moment. Check back soon!'
        });
        return null;
      }

      // Get random pet from available pets
      const availablePets = availablePetsSnapshot.docs;
      const randomIndex = Math.floor(Math.random() * availablePets.length);
      const selectedPet = availablePets[randomIndex];
      const petData = selectedPet.data();

      console.log(`Selected pet: ${petData.name} (${selectedPet.id})`);

      // Determine the best image to use
      let petImage = '';
      if (petData.imageUrls && Array.isArray(petData.imageUrls) && petData.imageUrls.length > 0) {
        petImage = petData.imageUrls[0];
      } else if (petData.image) {
        petImage = petData.image;
      }

      // Store the pet of the day with complete data (all fields with defaults to avoid undefined)
      await admin.firestore().collection('app_config').doc('pet_of_the_day').set({
        petId: selectedPet.id,
        petName: petData.name || 'Unknown',
        petSpecies: petData.species || 'Pet',
        petAge: petData.age || 'Unknown',
        petGender: petData.gender || 'Unknown',
        petBreed: petData.breed || 'Mixed',
        petImage: petImage,
        petDescription: petData.rescueStory || petData.description || `Meet ${petData.name || 'this adorable pet'}!`,
        petLocation: petData.location || 'Unknown',
        selectedAt: admin.firestore.FieldValue.serverTimestamp(),
        hasPet: true,
        // Store full pet data for easy access in the app
        fullPetData: {
          id: selectedPet.id,
          name: petData.name || '',
          species: petData.species || '',
          age: petData.age || '',
          gender: petData.gender || '',
          breed: petData.breed || '',
          breedType: petData.breedType || '',
          imageUrls: petData.imageUrls || [],
          image: petData.image || '',
          status: petData.status || '',
          location: petData.location || '',
          contactPhone: petData.contactPhone || '',
          rescueStory: petData.rescueStory || '',
          sterilization: petData.sterilization || '',
          vaccination: petData.vaccination || '',
          deworming: petData.deworming || '',
          motherStatus: petData.motherStatus || '',
          medicalIssues: petData.medicalIssues || '',
          postedBy: petData.postedBy || '',
          postedAt: petData.postedAt || null,
        }
      });

      console.log(`Pet of the Day updated successfully: ${petData.name} (${selectedPet.id})`);
      return null;
    } catch (error) {
      console.error('Error updating Pet of the Day:', error);
      throw error;
    }
  });

/**
 * HTTP endpoint to manually trigger Pet of the Day update
 * Useful for testing or manual refresh
 * 
 * Usage: POST to https://[region]-[project].cloudfunctions.net/refreshPetOfTheDay
 */
export const refreshPetOfTheDay = functions.https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      console.log('Manual Pet of the Day refresh triggered');

      // Query for available pets with correct status value
      const availablePetsSnapshot = await admin.firestore()
        .collection('animals')
        .where('status', '==', 'Available for Adoption')
        .where('approvalStatus', '==', 'approved')
        .where('isActive', '==', true)
        .get();

      console.log(`Found ${availablePetsSnapshot.docs.length} available pets`);

      if (availablePetsSnapshot.empty) {
        console.log('No available pets found');
        await admin.firestore().collection('app_config').doc('pet_of_the_day').set({
          selectedAt: admin.firestore.FieldValue.serverTimestamp(),
          hasPet: false,
          message: 'No pets available at the moment. Check back soon!'
        });
        
        res.status(200).json({
          success: true,
          message: 'No pets available',
          hasPet: false,
          totalPetsChecked: 0
        });
        return;
      }

      // Get random pet
      const availablePets = availablePetsSnapshot.docs;
      const randomIndex = Math.floor(Math.random() * availablePets.length);
      const selectedPet = availablePets[randomIndex];
      const petData = selectedPet.data();

      console.log(`Selected pet: ${petData.name} (${selectedPet.id})`);

      // Determine the best image to use
      let petImage = '';
      if (petData.imageUrls && Array.isArray(petData.imageUrls) && petData.imageUrls.length > 0) {
        petImage = petData.imageUrls[0];
      } else if (petData.image) {
        petImage = petData.image;
      }

      // Store the pet of the day with complete data (all fields with defaults to avoid undefined)
      await admin.firestore().collection('app_config').doc('pet_of_the_day').set({
        petId: selectedPet.id,
        petName: petData.name || 'Unknown',
        petSpecies: petData.species || 'Pet',
        petAge: petData.age || 'Unknown',
        petGender: petData.gender || 'Unknown',
        petBreed: petData.breed || 'Mixed',
        petImage: petImage,
        petDescription: petData.rescueStory || petData.description || `Meet ${petData.name || 'this adorable pet'}!`,
        petLocation: petData.location || 'Unknown',
        selectedAt: admin.firestore.FieldValue.serverTimestamp(),
        hasPet: true,
        // Store full pet data for easy access in the app
        fullPetData: {
          id: selectedPet.id,
          name: petData.name || '',
          species: petData.species || '',
          age: petData.age || '',
          gender: petData.gender || '',
          breed: petData.breed || '',
          breedType: petData.breedType || '',
          imageUrls: petData.imageUrls || [],
          image: petData.image || '',
          status: petData.status || '',
          location: petData.location || '',
          contactPhone: petData.contactPhone || '',
          rescueStory: petData.rescueStory || '',
          sterilization: petData.sterilization || '',
          vaccination: petData.vaccination || '',
          deworming: petData.deworming || '',
          motherStatus: petData.motherStatus || '',
          medicalIssues: petData.medicalIssues || '',
          postedBy: petData.postedBy || '',
          postedAt: petData.postedAt || null,
        }
      });

      console.log(`Pet of the Day saved to Firestore successfully`);

      res.status(200).json({
        success: true,
        message: `Pet of the Day updated: ${petData.name}`,
        hasPet: true,
        petId: selectedPet.id,
        petName: petData.name,
        petSpecies: petData.species,
        totalPetsAvailable: availablePets.length
      });
    } catch (error) {
      console.error('Error refreshing Pet of the Day:', error);
      res.status(500).json({
        success: false,
        error: 'Failed to refresh Pet of the Day',
        errorMessage: error instanceof Error ? error.message : String(error)
      });
    }
  });
});
