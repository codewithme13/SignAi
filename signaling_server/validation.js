/**
 * ============================================
 * SignAI - Input Validasyon Modülü
 * ============================================
 * Socket.IO ve REST API isteklerini doğrular.
 * Geçersiz verileri erkenden reddeder.
 * ============================================
 */

const { v4: uuidv4, validate: uuidValidate } = require('uuid');

/**
 * UUID formatı doğrula
 */
function isValidUUID(value) {
  return typeof value === 'string' && uuidValidate(value);
}

/**
 * Kullanıcı adı doğrula
 */
function isValidUsername(value) {
  if (typeof value !== 'string') return false;
  const trimmed = value.trim();
  return trimmed.length >= 2 && trimmed.length <= 50;
}

/**
 * SDP (Session Description Protocol) doğrula
 */
function isValidSDP(value) {
  if (!value || typeof value !== 'object') return false;
  return (
    typeof value.sdp === 'string' &&
    value.sdp.length > 0 &&
    typeof value.type === 'string' &&
    ['offer', 'answer', 'pranswer', 'rollback'].includes(value.type)
  );
}

/**
 * ICE Candidate doğrula
 */
function isValidIceCandidate(value) {
  if (!value || typeof value !== 'object') return false;
  return (
    typeof value.candidate === 'string' &&
    (typeof value.sdpMid === 'string' || value.sdpMid == null) &&
    (typeof value.sdpMLineIndex === 'number' || value.sdpMLineIndex == null)
  );
}

/**
 * Şifre doğrula
 */
function isValidPassword(password) {
  return typeof password === 'string' && 
         password.length >= 6 && 
         password.length <= 100;
}

/**
 * Socket Register verisini doğrula (sadece userId + username)
 */
function validateSocketRegisterData(data) {
  const errors = [];

  if (!data || typeof data !== 'object') {
    return { isValid: false, error: 'Geçersiz veri formatı' };
  }

  if (!isValidUUID(data.userId)) {
    errors.push('Geçersiz userId (UUID formatında olmalı)');
  }

  if (!isValidUsername(data.username)) {
    errors.push('Geçersiz username (2-50 karakter olmalı)');
  }

  return {
    isValid: errors.length === 0,
    error: errors.join(', '),
    sanitized: errors.length === 0 ? {
      userId: data.userId,
      username: data.username.trim().substring(0, 50),
    } : null,
  };
}

/**
 * Register verisini doğrula (username + password)
 */
function validateRegisterData(data) {
  const errors = [];

  if (!data || typeof data !== 'object') {
    return { isValid: false, error: 'Geçersiz veri formatı' };
  }

  if (!isValidUsername(data.username)) {
    errors.push('Geçersiz username (2-50 karakter olmalı)');
  }

  if (!isValidPassword(data.password)) {
    errors.push('Geçersiz password (6-100 karakter olmalı)');
  }

  return {
    isValid: errors.length === 0,
    error: errors.join(', '),
    sanitized: errors.length === 0 ? {
      username: data.username.trim().substring(0, 50),
      password: data.password,
    } : null,
  };
}

/**
 * Login verisini doğrula (username + password)  
 */
function validateLoginData(data) {
  const errors = [];

  if (!data || typeof data !== 'object') {
    return { isValid: false, error: 'Geçersiz veri formatı' };
  }

  if (!isValidUsername(data.username)) {
    errors.push('Geçersiz username');
  }

  if (!data.password || typeof data.password !== 'string') {
    errors.push('Password gerekli');
  }

  return {
    isValid: errors.length === 0,
    error: errors.join(', '),
    sanitized: errors.length === 0 ? {
      username: data.username.trim().substring(0, 50),
      password: data.password,
    } : null,
  };
}

/**
 * Call verisini doğrula
 */
function validateCallData(data) {
  const errors = [];

  if (!data || typeof data !== 'object') {
    return {
      isValid: false,
      error: 'Geçersiz veri formatı',
      valid: false,
      errors: ['Geçersiz veri formatı'],
    };
  }

  if (!isValidUUID(data.targetUserId)) {
    errors.push('Geçersiz targetUserId');
  }

  if (!isValidSDP(data.offer)) {
    errors.push('Geçersiz offer (SDP formatında olmalı)');
  }

  if (!data.callerInfo || typeof data.callerInfo !== 'object') {
    errors.push('Geçersiz callerInfo');
  }

  return {
    isValid: errors.length === 0,
    error: errors.join(', '),
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Answer verisini doğrula
 */
function validateAnswerData(data) {
  const errors = [];

  if (!data || typeof data !== 'object') {
    return {
      isValid: false,
      error: 'Geçersiz veri formatı',
      valid: false,
      errors: ['Geçersiz veri formatı'],
    };
  }

  if (!isValidUUID(data.targetUserId)) {
    errors.push('Geçersiz targetUserId');
  }

  if (!isValidSDP(data.answer)) {
    errors.push('Geçersiz answer (SDP formatında olmalı)');
  }

  return {
    isValid: errors.length === 0,
    error: errors.join(', '),
    valid: errors.length === 0,
    errors,
  };
}

/**
 * ICE Candidate verisini doğrula
 */
function validateIceCandidateData(data) {
  const errors = [];

  if (!data || typeof data !== 'object') {
    return {
      isValid: false,
      error: 'Geçersiz veri formatı',
      valid: false,
      errors: ['Geçersiz veri formatı'],
    };
  }

  if (!isValidUUID(data.targetUserId)) {
    errors.push('Geçersiz targetUserId');
  }

  if (!isValidIceCandidate(data.candidate)) {
    errors.push('Geçersiz ICE candidate');
  }

  return {
    isValid: errors.length === 0,
    error: errors.join(', '),
    valid: errors.length === 0,
    errors,
  };
}

module.exports = {
  isValidUUID,
  isValidUsername,
  isValidPassword,
  isValidSDP,
  isValidIceCandidate,
  validateSocketRegisterData,
  validateRegisterData,
  validateLoginData,
  validateCallData,
  validateAnswerData,
  validateIceCandidateData,
};
