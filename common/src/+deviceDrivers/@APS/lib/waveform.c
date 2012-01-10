/*
 * waveform.c
 *
 *  Created on: Aug 24, 2011
 *      Author: bdonovan
 */

#include "waveform.h"
#include "common.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

waveform_t * WF_Init() {
  waveform_t * wfArray;

  wfArray = (waveform_t *) malloc (MAX_APS_CHANNELS * sizeof(waveform_t));

  if (!wfArray) {
    dlog(DEBUG_INFO,"Failed to allocate memory for waveform array\n");
  }

  int cnt, bank;

  for (cnt = 0; cnt < MAX_APS_CHANNELS; cnt++) {
    wfArray[cnt].pData = 0;
    wfArray[cnt].pFormatedData = 0;
    wfArray[cnt].offset = 0.0;
    wfArray[cnt].scale = 1.0;
    wfArray[cnt].allocatedLength = 0;
    wfArray[cnt].isLoaded = 0;

    for (bank = 0; bank < 2; bank++) {
      wfArray[cnt].linkListBanks[bank].count = 0;
      wfArray[cnt].linkListBanks[bank].offset = 0;
      wfArray[cnt].linkListBanks[bank].trigger = 0;
      wfArray[cnt].linkListBanks[bank].repeat = 0;
      wfArray[cnt].linkListBanks[bank].length = 0;
    }

  }

  return wfArray;
}

void WF_Destroy(waveform_t * wfArray) {
  int cnt;

  if (!wfArray) return; // waveform array does not exist

  // free memory for each channel
  for (cnt = 0; cnt < MAX_APS_CHANNELS; cnt++) {
    WF_Free(wfArray,cnt);
  }

  // free channel array memory
  free(wfArray);
  return;
}

int    WF_SetWaveform(waveform_t * wfArray, int channel, float * data, int length) {
  if (!wfArray) return 0;

  // free any memory associated with channel if it exists
  WF_Free(wfArray,channel);

  // allocate memory

  int allocatedLength;

  // trim length to maximum allowed
  if (length > MAX_WAVEFORM_LENGTH) {
    dlog(DEBUG_INFO,"Warning trimming channel %i length to %i\n", channel, MAX_WAVEFORM_LENGTH);
    length =  MAX_WAVEFORM_LENGTH;
  }

  allocatedLength = length + (length % APS_WAVEFORM_UNIT_LENGTH);

  wfArray[channel].pData = (float *) malloc(allocatedLength * sizeof(float));
  if (!wfArray[channel].pData) {
    dlog(DEBUG_INFO,"Error allocating data pointer for channel: %i", channel);
    return -1;
  }

  wfArray[channel].pFormatedData = (int16_t *) malloc(allocatedLength * sizeof(int16_t));
  if (!wfArray[channel].pFormatedData) {
    dlog(DEBUG_INFO,"Error allocating formated data pointer for channel: %i", channel);
    return -1;
  }

  memset(wfArray[channel].pData,         0,  allocatedLength * sizeof(float));
  memset(wfArray[channel].pFormatedData, 0,  allocatedLength * sizeof(int16_t));

  memcpy(wfArray[channel].pData, data, length * sizeof(float));

  wfArray[channel].allocatedLength = allocatedLength;
  wfArray[channel].isLoaded = 0;
  WF_Prep(wfArray,channel);
  return 0;
}

int    WF_Free(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;

  if (wfArray[channel].pData) free(wfArray[channel].pData);
  if (wfArray[channel].pFormatedData) free(wfArray[channel].pFormatedData);

  // reset pointers to null
  wfArray[channel].pData = 0;
  wfArray[channel].pFormatedData = 0;

  int bank;

  for (bank = 0; bank < 2; bank++) {
    WF_FreeBank(&(wfArray[channel].linkListBanks[bank]));
  }

  return 0;
}

void WF_FreeBank(bank_t * bank) {
  if (bank->count)   free(bank->count);
  if (bank->offset)  free(bank->offset);
  if (bank->trigger) free(bank->trigger);
  if (bank->repeat)  free(bank->repeat);

    // reset pointer to NULL
  bank->count = 0;
  bank->offset = 0;
  bank->trigger = 0;
  bank->repeat = 0;
  bank->length = 0;
}

void  WF_SetOffset(waveform_t * wfArray,int channel, float offset) {
  if (!wfArray) return;
  wfArray[channel].offset = offset;
}

float    WF_GetOffset(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;
  return wfArray[channel].offset;
}

void    WF_SetScale(waveform_t * wfArray, int channel, float scale) {
  if (!wfArray) return;
  wfArray[channel].scale = scale;
}

float  WF_GetScale(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;
  return wfArray[channel].scale;
}

uint16_t * WF_GetDataPtr(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;

  return wfArray[channel].pFormatedData;
}

uint16_t WF_GetLength(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;

  return wfArray[channel].allocatedLength;
}

int WF_GetIsLoaded(waveform_t * wfArray, int channel) {
  if (!wfArray) return 0;

    return wfArray[channel].isLoaded;
}

void WF_SetIsLoaded(waveform_t * wfArray,  int channel, int loaded) {
  if (!wfArray) return;

  wfArray[channel].isLoaded = loaded;
}

void   WF_Prep(waveform_t * wfArray, int channel) {
  if (!wfArray) return;

  int cnt;
  int prepValue;

  float scale;
  float maxAbsValue;
  float offset;

  for (cnt = 0; cnt < wfArray[channel].allocatedLength; cnt++) {
    if (abs(wfArray[channel].pData[cnt]) > maxAbsValue)
        maxAbsValue = abs(wfArray[channel].pData[cnt]);
  }

  scale = wfArray[channel].scale * 1.0 / maxAbsValue;
  scale = scale * MAX_WF_VALUE;

  offset = wfArray[channel].offset * MAX_WF_VALUE;

  for (cnt = 0; cnt < wfArray[channel].allocatedLength; cnt++) {
    prepValue = wfArray[channel].pData[cnt];

    // multiply by scale and add dc offset
    prepValue = round(prepValue * scale + offset);

    // clip to min max value
    if (prepValue > MAX_WF_VALUE) prepValue = MAX_WF_VALUE;
    if (prepValue < -MAX_WF_VALUE) prepValue = -MAX_WF_VALUE;

    // convert to int16
    wfArray[channel].pFormatedData[cnt] = (int16_t) prepValue;
  }

}

int WF_SetLinkList(waveform_t * wfArray, int channel,
    uint16_t *OffsetData, uint16_t *CountData,
    uint16_t *TriggerData, uint16_t *RepeatData,
    int length, int bankID) {
  // Allocate memory for new link bank
  // Store link list data

  if (!wfArray) return -1;
  if (!OffsetData || ! CountData || !TriggerData || !RepeatData)
     return -3; // require every data type
  if (bankID < 0 || bankID > 1) return -4;
  if (length == 0) return -5;
  if (channel > MAX_APS_CHANNELS) return -6;

  bank_t * bank;

  bank = &(wfArray[channel].linkListBanks[bankID]);

  // check for existing link list data and free it
  if (bank->length > 0)
    WF_FreeBank(bank);

  // allocate memory for entries

  bank->offset  = (uint16_t *) malloc(length * sizeof(uint16_t));
  bank->count   = (uint16_t *) malloc(length * sizeof(uint16_t));
  bank->trigger = (uint16_t *) malloc(length * sizeof(uint16_t));
  bank->repeat  = (uint16_t *) malloc(length * sizeof(uint16_t));

  if (!bank->offset || !bank->count || !bank->trigger || !bank->repeat) {
    WF_FreeBank(bank);
    dlog(DEBUG_INFO,"Error allocating link list bank for channel: %i", channel);
    return -7;
  }

  memcpy(bank->offset,  OffsetData,  length * sizeof(uint16_t));
  memcpy(bank->count,   CountData,   length * sizeof(uint16_t));
  memcpy(bank->trigger, TriggerData, length * sizeof(uint16_t));
  memcpy(bank->repeat,  RepeatData,  length * sizeof(uint16_t));

  bank->length = length;
  return 0;
}
