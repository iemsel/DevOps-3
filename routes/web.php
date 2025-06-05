<?php

use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ProjectController;
use App\Http\Controllers\TaskController;


Route::get('/', function () {
    return view('about');
})->middleware(['auth', 'verified'])->name('dashboard');

require __DIR__.'/auth.php';
/*
 * The home routes
 */
Route::get('/home', [TaskController::class, 'index'])->name('home');

/*
 * The resource routes
 */
Route::resource('tasks', TaskController::class)
    ->except(['index']); // removed this route because this is moved to the home route
Route::post('tasks/{task}/complete', [TaskController::class, 'complete'])
    ->name('tasks.complete');
Route::resource('posts', PostController::class);
Route::resource('projects', ProjectController::class);

/*
 * Route that shows the about page. This handler just returns the about view.
 */
Route::view('/about', 'about')->name('about');