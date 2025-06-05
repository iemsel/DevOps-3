<?php

use App\Http\Controllers\ProfileController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ProjectController;
use App\Http\Controllers\TaskController;
use Illuminate\Support\Facades\Route;

require __DIR__.'/auth.php';

// Redirect root to login
Route::get('/', function () {
    return redirect()->route('login');
});

// Everything else should be protected
Route::middleware(['auth', 'verified'])->group(function () {
    // The about/dashboard page
    Route::view('/about', 'about')->name('about');

    // Home route
    Route::get('/home', [TaskController::class, 'index'])->name('home');

    // Resource routes
    Route::resource('tasks', TaskController::class)->except(['index']);
    Route::post('tasks/{task}/complete', [TaskController::class, 'complete'])->name('tasks.complete');
    Route::resource('posts', PostController::class);
    Route::resource('projects', ProjectController::class);

    // Profile
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});
